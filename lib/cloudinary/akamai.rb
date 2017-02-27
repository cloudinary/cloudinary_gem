require 'openssl'

module Cloudinary
  module Akamai
    SEPARATOR = '~'

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def generate_token(options)
        key = options[:key] || Cloudinary.config.akamai_key
        raise "Missing akamai_key configuration" unless key
        name = options[:token_name] || "__cld_token__"
        start = options[:start_time]
        expiration = options[:end_time]
        ip = options[:ip]
        acl = options[:acl]
        window = options[:window]

        start = Time.new.getgm.to_i if start == 'now'
        unless expiration
          if window
            expiration = (start || Time.new.getgm.to_i) + window
          else
            raise 'Must provide either end_time or window'
          end
        end

        token = []
        token << "ip=#{ip}" if ip
        token << "st=#{start}" if start
        token << "exp=#{expiration}"
        token << "acl=#{acl}"
        auth = digest(token.join(SEPARATOR), key)
        token << "hmac=#{auth}"
        "#{name}=#{token.join(SEPARATOR)}"
      end

      private

      def digest(message, key = Cloudinary.config.akamai_key)
        bin_key = Array(key).pack("H*")
        digest = OpenSSL::Digest::SHA256.new
        OpenSSL::HMAC.hexdigest(digest, bin_key, message)
      end
    end
  end
end