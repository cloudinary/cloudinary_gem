# frozen_string_literal: true
ENV['RAILS_ENV'] ||= 'test'
require_relative './dummy/config/environment'

require 'rspec'

# require_relative "shared_service_tests"
require "bundler/setup"
require "active_support"
# require "active_support/test_case"
# require "active_support/testing/autorun"

require "net/http"
# require "test_helper"
require "active_support/core_ext/securerandom"
require "database/setup"
require 'active_storage/blob_key'

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
