# rubocop:disable ClassVars
module RailsMultisite
  # Overloaded connection management
  class ConnectionManagement

    @@manager = Manager::Dummy.new

    def initialize(app)
      @@app = app
    end

    def call(env)
      p "DEBUG: #{env}"
      @@manager.call @@app, env
    end

    def self.manager
      @@manager
    end

    def self.config_filename=(config_filename)
      @@config_filename = config_filename
    end

    def self.config_filename
      @@config_filename ||= RailsMultisite::Configuration.config_filename
    end

    def self.clear_settings!
      @@manager = Manager::Dummy.new
    end

    def self.load_settings!(config_filename = nil)
      self.config_filename = config_filename if config_filename
      config = Configuration.config_from_file self.config_filename
      specs_store = Configuration.specs_store_for_config config
      @@manager = Manager::Real.new specs_store, config


    end

    def self.host(env)
      @@manager.host_name_from_env env
    end

    def self.each_connection(&block)
      @@manager.each_connection(&block)
    end

    def self.establish_connection(selector)
      return @@manager.set_current_handler_by_host selector[:host] if selector[:host]
      return @@manager.set_current_handler_by_database_name selector[:db]
    end

    def self.all_dbs
      # This call is too expensive and not tenable for a large
      # scale multi-site app. Discourse will sometimes tell
      # sidekiq to 'do something', and it appears if it doesn't
      # expliciting give a :db, sidekiq chooses to do it on ALL
      # databases. We are going to disable this for now.

      [] #@@manager.all_database_names
    end

    def self.current_db
      @@manager.current_database_name
    end

    def self.current_hostname
      @@manager.current_host
    end

    def self.has_db?(database_name)
      @@manager.database_name? database_name
    end

    def self.with_hostname(host, &block)
      @@manager.with_handler_of_host host, &block
    end

    def self.with_connection(database_name = 'default', &block)
      @@manager.with_handler_of_database_name database_name, &block
    end
  end
end
