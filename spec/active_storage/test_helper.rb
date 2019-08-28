# frozen_string_literal: true
ENV['RAILS_ENV'] ||= 'test'
require_relative './dummy/config/environment'

require "bundler/setup"
require "active_support"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_storage/engine"
require "net/http"
require "active_support/core_ext/securerandom"
require "active_storage/database/setup"

begin
  require "byebug"
rescue LoadError
end

require "active_job"
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = ActiveSupport::Logger.new(nil)


require "yaml"
SERVICE_CONFIGURATIONS = begin
  erb = ERB.new(Pathname.new(File.expand_path("service/configurations.yml", __dir__)).read)
  configuration = YAML.load(erb.result) || {}
  configuration.deep_symbolize_keys
rescue Errno::ENOENT
  puts "Missing service configuration file in test/service/configurations.yml"
  {}
end

ActiveStorage.logger = ActiveSupport::Logger.new(nil)
ActiveStorage.verifier = ActiveSupport::MessageVerifier.new("Testing")

require "global_id"
GlobalID.app = "ActiveStorageExampleApp"
ActiveRecord::Base.send :include, GlobalID::Identification
