require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development)))
end

module Basic
  class Application < Rails::Application
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true
  end
end
