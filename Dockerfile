FROM ruby:3.2-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm \
    yarn \
    git \
    tzdata

WORKDIR /app

# Copy and install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 && \
    bundle install --without development test && \
    bundle clean --force

# Copy and install Node dependencies
COPY package.json yarn.lock ./
RUN yarn install --production --frozen-lockfile && \
    yarn cache clean

# Production stage
FROM ruby:3.2-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    postgresql-client \
    nodejs \
    tzdata \
    curl \
    && addgroup -g 1000 app \
    && adduser -D -s /bin/sh -u 1000 -G app app

WORKDIR /app

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code
COPY --chown=app:app . .

# Create necessary directories
RUN mkdir -p logs tmp public && \
    chown -R app:app /app

# Switch to non-root user
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma_simple.rb"]
