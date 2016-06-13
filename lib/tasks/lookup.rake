namespace :multisite do

  namespace :lookup do

    def setup_lookups_tasks_enviroment

      config = RailsMultisite::Configuration.config_from_file RailsMultisite::Configuration.config_filename

      databases = config[ :lookup ]

      migrations_paths = [ RailsMultisite::LOOKUPS_MIGRATIONS_PATH ]

      RailsMultisite::Tasks.set_databases_settings databases, migrations_paths

    end

    task :rake_dodge do

      RailsMultisite::Railtie.rake_dodge = true

    end

    desc 'execute specified rake task for all lookup databases in tier'
    task :each, [ :task_name ] => [ :rake_dodge, :environment ] do | rt, args |

      task_name = args.task_name

      setup_lookups_tasks_enviroment

      abort 'no lookup tables' if ActiveRecord::Tasks::DatabaseTasks.database_configuration.empty?

      databases = ActiveRecord::Tasks::DatabaseTasks.database_configuration

      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new databases

      handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new

      ActiveRecord::Base.connection_handler = handler

      databases.each do | name, config |

        spec = resolver.spec name.to_sym

        handler.establish_connection ActiveRecord::Base, spec

        puts "Executing rake #{ task_name } #{ name }"
        puts "---------------------------------\n"

        RailsMultisite::Tasks.execute_task task_name

        handler.clear_active_connections!

      end

    end

    desc 'task for all lookup databases'
    task :together, [ :task_name ] => [ :rake_dodge, :environment ] do | rt, args |

      task_name = args.task_name

      setup_lookups_tasks_enviroment

      abort 'no lookup tables' if ActiveRecord::Base.configurations.empty?

      RailsMultisite::Tasks.execute_task task_name

    end

  end

end
