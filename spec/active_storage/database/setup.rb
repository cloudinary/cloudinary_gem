# frozen_string_literal: true

require_relative "create_users_migration"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.migration_context.migrate
ActiveStorageCreateUsers.migrate(:up)
