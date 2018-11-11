class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def rate_limit(limit_timespan, allowed_request)
    client_ip = request.remote_ip
    key = "request_count:#{client_ip}"
    request_count = $redis.get(key)

    unless request_count
      $redis.set(key,0)
      $redis.expire(client_ip, limit_timespan.to_i)
      return true
    end

    if request_count.to_i > allowed_request
      # write something into the log file for alerting
      Rails.logger.warn "Overheat: User with ip #{client_ip} is over usage limit."

      render :status => 429, :json => {:message => "You have fired too many requests. Please wait for #{$redis.ttl client_ip} seconds."}
      return
    end
    $redis.incr(key)
    true
  end
end
