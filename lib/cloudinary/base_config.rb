module Cloudinary
  class BaseConfig
    def initialize(config_path)
      @config = OpenStruct.new((YAML.load(ERB.new(IO.read(config_path)).result)[config_env] rescue {}))

      load_config_from_env
    end

    def load_from_url(url)
      return unless url && !url.empty?

      parsed_url = URI.parse(url)
      scheme = parsed_url.scheme.to_s.downcase

      if expected_scheme != scheme
        raise(CloudinaryException,
              "Invalid #{self.class::ENV_URL} scheme. Expecting to start with '#{expected_scheme}://'")
      end

      update(config_from_parsed_url(parsed_url))
      setup_from_parsed_url(parsed_url)
    end

    def update(new_config = {})
      new_config.each{ |k,v| config.send(:"#{k}=", v) unless v.nil?}
    end

    def method_missing(method_name, *args, &block)
      config.public_send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private)
      config.respond_to?(method_name, include_private)
    end

    private

    attr_reader :config

    def config_from_parsed_url(parsed_url)
      raise NotImplementedError
    end

    def load_config_from_env
      raise NotImplementedError
    end

    def expected_scheme
      self.class::SCHEME
    end

    def put_nested_key(key, value)
      chain   = key.split(/[\[\]]+/).reject(&:empty?)
      outer   = config
      lastKey = chain.pop
      chain.each do |innerKey|
        inner = outer[innerKey]
        if inner.nil?
          inner           = OpenStruct.new
          outer[innerKey] = inner
        end
        outer = inner
      end
      outer[lastKey] = value
    end

    def is_nested_key?(key)
      /\w+\[\w+\]/ =~ key
    end

    def setup_from_parsed_url(parsed_url)
      parsed_url.query.to_s.split("&").each do |param|
        key, value = param.split("=")
        if is_nested_key? key
          put_nested_key key, value
        else
          update(key => Utils.smart_unescape(value))
        end
      end
    end
  end
end
