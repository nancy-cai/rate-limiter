require 'redis'

class RateLimiter
  class << self
    attr_reader :app
    attr_accessor :max_requests, :limit_timespan

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      if throttled?(request)
        respond_throttled(request)
      else
        @app.call(env)
      end
    end

    def get_client_ip(request)
      return request.remote_ip
    end

    def throttled?(request)
      client_ip = get_client_ip(request)
      key = "request_count:#{client_ip}"
      request_count = $redis.get(key)

      if !$redis.exists client_ip
        $redis.multi do
          $redis.set client_ip, 1
          $redis.expire client_ip, limit_timespan.to_i
        end
      else
        $redis.incr(key)
        if request_count.to_i > max_requests
          # write something into the log file for alerting
          Rails.logger.warn "Overheat: User with ip #{client_ip} is over usage limit."
          return true
        end
      end
      return false
    end

    def respond_throttled(request)
      [429, {}, ["You have fired too many requests. Please try in #{$redis.ttl get_client_ip(request)} seconds"]]
    end

    def max_requests
      self.class.max_requests
    end

    def limit_timespan
      self.class.limit_timespan
    end

  end
end
