require 'openssl'

module Cloudinary
  module Akamai
    SEPARATOR = '~'

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def generate_auth_token(options = {})
        options = (Cloudinary.config.auth_token || {}).to_h.merge options
        key = options[:key]
        throw "Missing auth token key configuration" unless key
        name = options[:token_name] || "__cld_token__"
        start = options[:start_time]
        expiration = options[:expiration]
        ip = options[:ip]
        acl = options[:acl]
        duration = options[:duration]
        url = options[:url]
        start = Time.new.getgm.to_i if start == 'now'
        unless expiration
          if duration
            expiration = (start || Time.new.getgm.to_i) + duration
          else
            throw 'Must provide either expiration or duration'
          end
        end

        token = []
        token << "ip=#{ip}" if ip
        token << "st=#{start}" if start
        token << "exp=#{expiration}"
        token << "acl=#{acl}" if acl
        to_sign = token.clone
        if url
          url = CGI::escape(url).gsub(/%../){|h| h.downcase}
          to_sign << "url=#{url}"
        end
        auth = digest(to_sign.join(SEPARATOR), key)
        token << "hmac=#{auth}"
        "#{name}=#{token.join(SEPARATOR)}"
      end

      private

      def digest(message, key)
        bin_key = Array(key).pack("H*")
        digest = OpenSSL::Digest::SHA256.new
        OpenSSL::HMAC.hexdigest(digest, bin_key, message)
      end
    end
  end
end