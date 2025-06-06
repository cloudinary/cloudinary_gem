require "faraday"
require "json"

module Cloudinary::BaseApi
  @adapter = nil
  class Error < CloudinaryException; end
  class NotFound < Error; end
  class NotAllowed < Error; end
  class AlreadyExists < Error; end
  class RateLimited < Error; end
  class BadRequest < Error; end
  class GeneralError < Error; end
  class AuthorizationRequired < Error; end

  class Response < Hash
    attr_reader :rate_limit_reset_at, :rate_limit_remaining, :rate_limit_allowed

    def initialize(response=nil)
      unless response
        return
      end

      # This sets the instantiated self as the response Hash
      update Cloudinary::Api.parse_json_response response

      # According to RFC 2616, header names are case-insensitive.
      lc_headers            = response.headers.transform_keys(&:downcase)

      @rate_limit_allowed   = lc_headers["x-featureratelimit-limit"].to_i if lc_headers["x-featureratelimit-limit"]
      @rate_limit_reset_at  = Time.parse(lc_headers["x-featureratelimit-reset"]) if lc_headers["x-featureratelimit-reset"]
      @rate_limit_remaining = lc_headers["x-featureratelimit-remaining"].to_i if lc_headers["x-featureratelimit-remaining"]
    end
  end

  def self.extended(base)
    [Error, NotFound, NotAllowed, AlreadyExists, RateLimited, BadRequest, GeneralError, AuthorizationRequired, Response].each do |constant|
      base.const_set(constant.name.split("::").last, constant)
    end
  end

  def call_json_api(method, api_url, payload, timeout, headers, proxy = nil, user = nil, password = nil)
    conn = Faraday.new(url: api_url) do |faraday|
      faraday.proxy = proxy if proxy
      faraday.request :json
      faraday.adapter @adapter || Faraday.default_adapter
    end

    response = conn.run_request(method.downcase.to_sym, nil, payload, headers) do |req|
      req.options.timeout = timeout if timeout
      req.basic_auth(user, password) if user && password
    end

    return Response.new(response) if response.status == 200
    exception_class = case response.status
                      when 400 then BadRequest
                      when 401 then AuthorizationRequired
                      when 403 then NotAllowed
                      when 404 then NotFound
                      when 409 then AlreadyExists
                      when 420, 429 then RateLimited
                      when 500 then GeneralError
                      else raise GeneralError.new("Server returned unexpected status code - #{response.status} - #{response.body}")
                      end
    json = Cloudinary::Api.parse_json_response(response)
    raise exception_class.new(json["error"]["message"])
  end

  private

  def call_cloudinary_api(method, uri, auth, params, options, &api_url_builder)
    cloudinary = options[:upload_prefix] || Cloudinary.config.upload_prefix || 'https://api.cloudinary.com'
    api_url    = Cloudinary::Utils.smart_escape(api_url_builder.call(cloudinary, uri).flatten.join('/'))
    timeout    = options[:timeout] || Cloudinary.config.timeout || 60
    proxy      = options[:api_proxy] || Cloudinary.config.api_proxy

    headers = { "User-Agent" => Cloudinary::USER_AGENT }
    headers.merge!("Authorization" => get_authorization_header_value(auth))

    if options[:content_type] == :json
      payload = params.to_json
      headers.merge!("Content-Type" => "application/json", "Accept" => "application/json")
    else
      payload = params.reject { |_, v| v.nil? || v == "" }
    end

    call_json_api(method, api_url, payload, timeout, headers, proxy)
  end

  def get_authorization_header_value(auth)
    if auth[:oauth_token].present?
      "Bearer #{auth[:oauth_token]}"
    else
      "Basic #{Base64.urlsafe_encode64("#{auth[:key]}:#{auth[:secret]}")}"
    end
  end

  def validate_authorization(api_key, api_secret, oauth_token)
    return if oauth_token.present?

    raise("Must supply api_key") if api_key.nil?
    raise("Must supply api_secret") if api_secret.nil?
  end
end
