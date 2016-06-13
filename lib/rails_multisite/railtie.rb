module RailsMultisite

  class Railtie < Rails::Railtie

    @@rake_dodge = false

    def self.rake_dodge= ( bool )

      @@rake_dodge = bool

    end


    rake_tasks do

      Dir[ File.join( File.dirname( __FILE__ ), '../tasks/*.rake' ) ].each { | f | load f }
      
    end

    initializer 'RailsMultisite.init' do | app |

      # By default, declare that we are inactive.
      app.config.multisite = false

      next if @@rake_dodge

      # If the file is deleted, just abort early.
      next unless File.exists?( RailsMultisite::Configuration.config_filename )

      # File exists and :multisite present, we are active!
      app.config.multisite = true
      
      RailsMultisite::ConnectionManagement.load_settings!

      # This is the database connection stuff that Rails provides
      old_middleware = ActiveRecord::ConnectionAdapters::ConnectionManagement

      # This is our database connection stuff
      new_middleware = RailsMultisite::ConnectionManagement

      # Swap in our middleware.
      app.middleware.swap old_middleware, new_middleware

      if ENV[ 'RAILS_DB' ]

        RailsMultisite::ConnectionManagement.establish_connection db: ENV[ 'RAILS_DB' ]
      
      end

    end

  end

end
