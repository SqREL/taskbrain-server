# frozen_string_literal: true

require 'openssl'
require 'base64'

class SecurityUtils
  def self.encryption_key
    @encryption_key ||= begin
      if ENV['ENCRYPTION_KEY']
        Base64.strict_decode64(ENV['ENCRYPTION_KEY'])
      else
        generate_key
      end
    end
  end

  def self.generate_key
    key = OpenSSL::Random.random_bytes(32)
    encoded_key = Base64.strict_encode64(key)
    puts "⚠️  Generated new encryption key. Set ENCRYPTION_KEY=#{encoded_key} in your environment"
    key
  end

  def self.encrypt(data)
    return data if data.nil? || (data.respond_to?(:empty?) && data.empty?)

    cipher = OpenSSL::Cipher.new('AES-256-GCM')
    cipher.encrypt
    cipher.key = encryption_key

    iv = cipher.random_iv
    encrypted = cipher.update(data.to_s) + cipher.final
    auth_tag = cipher.auth_tag

    # Combine iv + auth_tag + encrypted data
    combined = iv + auth_tag + encrypted
    Base64.strict_encode64(combined)
  end

  def self.decrypt(encrypted_data)
    return nil if encrypted_data.nil? || encrypted_data.empty?

    begin
      combined = Base64.strict_decode64(encrypted_data)

      # Extract components
      iv = combined[0, 12]
      auth_tag = combined[12, 16]
      encrypted = combined[28..]

      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.decrypt
      cipher.key = encryption_key
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      cipher.update(encrypted) + cipher.final
    rescue StandardError => e
      puts "⚠️  Decryption failed: #{e.message}"
      nil
    end
  end

  def self.secure_store_token(redis, key, token, ttl = 3600)
    encrypted_token = encrypt(token)
    redis.setex(key, ttl, encrypted_token)
  end

  def self.secure_get_token(redis, key)
    encrypted_token = redis.get(key)
    return nil unless encrypted_token

    decrypt(encrypted_token)
  end

  def self.hash_api_key(api_key)
    OpenSSL::PKCS5.pbkdf2_hmac(
      api_key,
      ENV['API_KEY_SALT'] || 'taskbrain_salt',
      10_000,
      32,
      OpenSSL::Digest.new('SHA256')
    )
  end

  def self.generate_secure_token(length = 32)
    SecureRandom.urlsafe_base64(length)
  end
end
