namespace :multisite do

  def run_task ( name )

    RailsMultisite::ConnectionManagement.manager.each_connection do | db |

      puts "Executing rake #{ name } #{ db }"
      puts "---------------------------------\n"

      RailsMultisite::Tasks.execute_task name

    end

  end

  desc 'migrate all sites in tier'
  task migrate: :environment do

    run_task 'db:migrate'

  end

  desc 'seed all sites in tier'
  task seed_fu: :environment do

    run_task 'db:seed_fu'

  end

  desc 'rollback migrations for all sites in tier'
  task rollback: :environment do

    run_task 'db:rollback'

  end

  desc 'execute specified rake task for all sites in tier'
  task :each, [ :task_name ] => :environment do | t, args |

    run_task args.task_name

  end

  desc 'create all sites'
  task :together, [ :task_name ] => :environment do | t, args |

    task_name = args.task_name

    databases = RailsMultisite::ConnectionManagement.manager.all_databases

    RailsMultisite::Tasks.set_databases_settings databases

    abort 'no lookup tables' if ActiveRecord::Base.configurations.empty?

    RailsMultisite::Tasks.execute_task task_name

  end

end
