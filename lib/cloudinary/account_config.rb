module Cloudinary
  class AccountConfig < BaseConfig
    ENV_URL = "CLOUDINARY_ACCOUNT_URL"
    SCHEME = "account"

    private

    def config_from_parsed_url(parsed_url)
      {
        "account_id"              => parsed_url.host,
        "provisioning_api_key"    => parsed_url.user,
        "provisioning_api_secret" => parsed_url.password
      }
    end

    def load_config_from_env
      load_from_url(ENV[ENV_URL]) if ENV[ENV_URL]
    end
  end
end
