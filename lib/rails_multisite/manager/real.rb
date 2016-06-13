# rubocop:disable AccessorMethodName
module RailsMultisite

  module Manager
    # Implementation of Manager
    class Real < Base

      # TODO: fix miss caching
      class UnfoundSpecError < StandardError; end

      def initialize(store, config)
        p "store", store.inspect, "config", config
        @specs_store = store
        @name_handler_cache = Configuration.cache_store_for_config config
        @host_handler_cache = Configuration.cache_store_for_config config
      end

      def call(app, env)
        host = host_name_from_env env
        handler = handler_for_host host
        return [404, {}, ['not found']] unless handler

        begin
          clear_connections
          set_current_handler handler
          app.call env
        ensure
          clear_connections
        end
      end

      def each_connection(&block)
        # This call is too expensive and not tenable for a large
        # scale multi-site app. Discourse only uses it in external
        # scripts, but unfortunately calls it from sidekiq
        # in an attempt to pre-cache ALL handlers. In the event
        # it's from sidekiq, we are going to give it no love.
        return if Kernel.caller.to_s.include?("-sidekiq.rb")

        previous_handler = current_handler
        was_connected = ActiveRecord::Base.connected?
        @specs_store.each do |name, spec|
#          handler = handler_for_spec spec
 #         set_current_handler handler
          block.call name unless name == 'default'
  #        clear_connections
        end

        set_current_handler previous_handler
        clear_connections unless was_connected
      end

      # TODO: add caching of names
      def all_database_names
        @specs_store.names
      end

      # TODO: check posibility to remove 'default'
      def current_database_name
        ActiveRecord::Base.connection_pool.spec.config[:name] || 'default'
      end

      def database_name?(name)
        @specs_store.include_named? name
      end

      def set_current_handler_by_host(host)
        set_current_handler_by :handler_for_host, host
      end

      def set_current_handler_by_database_name(name)
        set_current_handler_by :handler_for_database_name, name
      end

      def with_handler_of_host(host, &block)
        with_handler_of :handler_for_host, host, &block
      end

      def with_handler_of_database_name(name, &block)
        with_handler_of :handler_for_database_name, name, &block
      end

      def all_databases
        @specs_store.databases
      end

      protected

      def with_handler_of(search_handler_method, key, &block)
        previous_handler = current_handler
        was_connected = ActiveRecord::Base.connected?

        set_current_handler_by search_handler_method, key
        result = block.call key

        return result if was_connected && previous_handler == current_handler
        clear_connections
        set_current_handler previous_handler
        clear_connections unless was_connected
        result
      end

      def set_current_handler_by(search_handler_method, key)
        handler = send search_handler_method, key
        fail UnfoundSpecError, "fail to find database configuration for #{key}" unless handler
        set_current_handler handler
        handler
      end

      def clear_connections
        ActiveRecord::Base.connection_handler.clear_active_connections!
      end

      def set_current_handler(handler)
        ActiveRecord::Base.connection_handler = handler
      end

      def current_handler
        ActiveRecord::Base.connection_handler
      end

      def handler_for_host(host)
        handler_for :find_by_host, host, @host_handler_cache
      end

      def handler_for_database_name(name)
        handler_for :find_by_name, name, @name_handler_cache
      end

      def handler_for(seach_method, key, cache)
        spec = cache[key]

        return spec if spec

        spec = @specs_store.send seach_method, key
        handler = spec ? handler_for_spec(spec) : nil
        cache[key] = handler
      end

      def handler_for_spec(spec)
        p "SPEC = #{spec}"
        p "#{Kernel.caller}"
        name = spec.config[:name]
        p "name=#{name}"

        handler = @name_handler_cache[name]
        return handler if handler

        handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        handler.establish_connection ActiveRecord::Base, spec
        @name_handler_cache[name] = handler
      end
    end
  end
end
