# frozen_string_literal: true

require_relative "create_users_migration"

module YAML
  class << self
    alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
  end
end

connection = ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
if connection.respond_to?(:migration_context)
  connection.migration_context.migrate
else
  # Fallback for older versions of Rails
  ActiveRecord::Base.connection.migration_context.migrate
end

ActiveStorageCreateUsers.migrate(:up)
