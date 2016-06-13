module RailsMultisite

  module Tasks

    def self.set_databases_settings ( databases, migrations_paths = nil )

      ActiveRecord::Tasks::DatabaseTasks.database_configuration = databases
      ActiveRecord::Base.configurations = databases

      if migrations_paths

        ActiveRecord::Tasks::DatabaseTasks.migrations_paths = migrations_paths
        ActiveRecord::Migrator.migrations_paths = migrations_paths

      end

      ActiveRecord::Base.dump_schema_after_migration = false

    end

  end

end
