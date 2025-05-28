# frozen_string_literal: true

require 'httparty'
require 'uri'

class GoogleCalendarIntegration
  include HTTParty
  base_uri 'https://www.googleapis.com'

  def initialize(client_id, client_secret)
    @client_id = client_id
    @client_secret = client_secret
  end

  def exchange_code(code)
    response = self.class.post('/oauth2/v4/token', {
                                 body: {
                                   client_id: @client_id,
                                   client_secret: @client_secret,
                                   code: code,
                                   grant_type: 'authorization_code',
                                   redirect_uri: "#{ENV['BASE_URL']}/auth/google/callback"
                                 }
                               })

    if response.success?
      {
        success: true,
        access_token: response['access_token'],
        refresh_token: response['refresh_token']
      }
    else
      {
        success: false,
        error: response['error_description'] || 'Authentication failed'
      }
    end
  end

  def refresh_access_token(refresh_token)
    response = self.class.post('/oauth2/v4/token', {
                                 body: {
                                   client_id: @client_id,
                                   client_secret: @client_secret,
                                   refresh_token: refresh_token,
                                   grant_type: 'refresh_token'
                                 }
                               })

    response.success? ? response['access_token'] : nil
  end

  def get_events_for_date(date, access_token = nil)
    access_token ||= get_current_access_token
    return [] unless access_token

    start_time = DateTime.parse(date).beginning_of_day.iso8601
    end_time = DateTime.parse(date).end_of_day.iso8601

    response = self.class.get('/calendar/v3/calendars/primary/events', {
                                headers: { 'Authorization' => "Bearer #{access_token}" },
                                query: {
                                  timeMin: start_time,
                                  timeMax: end_time,
                                  singleEvents: true,
                                  orderBy: 'startTime'
                                }
                              })

    if response.success?
      events = response['items'] || []
      events.map { |event| format_event(event) }
    else
      []
    end
  end

  def get_free_busy(start_time, end_time, access_token = nil)
    access_token ||= get_current_access_token
    return {} unless access_token

    response = self.class.post('/calendar/v3/freeBusy', {
                                 headers: {
                                   'Authorization' => "Bearer #{access_token}",
                                   'Content-Type' => 'application/json'
                                 },
                                 body: {
                                   timeMin: start_time,
                                   timeMax: end_time,
                                   items: [{ id: 'primary' }]
                                 }.to_json
                               })

    response.success? ? response.parsed_response : {}
  end

  def create_event(event_data, access_token = nil)
    access_token ||= get_current_access_token
    return nil unless access_token

    response = self.class.post('/calendar/v3/calendars/primary/events', {
                                 headers: {
                                   'Authorization' => "Bearer #{access_token}",
                                   'Content-Type' => 'application/json'
                                 },
                                 body: event_data.to_json
                               })

    response.success? ? response.parsed_response : nil
  end

  def find_available_slots(date, duration_minutes, access_token = nil)
    events = get_events_for_date(date, access_token)

    # Define work hours (9 AM to 6 PM)
    work_start = DateTime.parse("#{date} 09:00")
    work_end = DateTime.parse("#{date} 18:00")

    busy_periods = events.map do |event|
      {
        start: DateTime.parse(event[:start_time]),
        end: DateTime.parse(event[:end_time])
      }
    end.sort_by { |period| period[:start] }

    available_slots = []
    current_time = work_start

    busy_periods.each do |busy_period|
      # Check gap before this busy period
      if current_time + (duration_minutes / 1440.0) <= busy_period[:start]
        available_slots << {
          start: current_time,
          end: busy_period[:start],
          duration: ((busy_period[:start] - current_time) * 1440).to_i
        }
      end
      current_time = [current_time, busy_period[:end]].max
    end

    # Check remaining time after last busy period
    if current_time + (duration_minutes / 1440.0) <= work_end
      available_slots << {
        start: current_time,
        end: work_end,
        duration: ((work_end - current_time) * 1440).to_i
      }
    end

    # Filter slots that can accommodate the required duration
    available_slots.select { |slot| slot[:duration] >= duration_minutes }
  end

  private

  def get_current_access_token
    token = $redis.get('google_token')
    refresh_token = $redis.get('google_refresh_token')

    return token if token && !token_expired?(token)

    return unless refresh_token

    new_token = refresh_access_token(refresh_token)
    $redis.setex('google_token', 3600, new_token) if new_token
    new_token
  end

  def token_expired?(_token)
    # Simple check - in production, you'd want to decode JWT and check expiry
    false
  end

  def format_event(event)
    {
      id: event['id'],
      summary: event['summary'],
      start_time: event['start']['dateTime'] || event['start']['date'],
      end_time: event['end']['dateTime'] || event['end']['date'],
      location: event['location'],
      description: event['description'],
      attendees: event['attendees']&.map { |a| a['email'] },
      busy: event['transparency'] != 'transparent'
    }
  end
end
