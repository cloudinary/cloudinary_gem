# frozen_string_literal: true

require_relative "create_users_migration"

module YAML
  class << self
    alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
  end
end
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.migration_context.migrate
ActiveStorageCreateUsers.migrate(:up)
