
module ChatManager
  module Generators
    class ModelingGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def add_migrations
        migration_template "db/migrate/create_chat_manager_chat.rb", "db/migrate/create_chat_manager_chat.rb"
      end
    end
  end
end
