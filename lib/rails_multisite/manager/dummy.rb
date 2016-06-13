# rubocop:disable AccessorMethodName

module RailsMultisite
  module Manager
    # Class for testing
    class Dummy < Base

      class NotDefaultNameError < StandardError; end

      def each_connection(&block)
        block.call 'default'
      end

      def all_database_names
        ['default']
      end

      def current_database_name
        'default'
      end

      def database_name?(name)
        name == 'default'
      end

      def set_current_handler_by_host(host)
      end

      def set_current_handler_by_database_name(name)
        check_that_name_is_default name
        ActiveRecord::Base.establish_connection unless ActiveRecord::Base.connection_handler.retrieve_connection_pool(ActiveRecord::Base)
      end

      def with_handler_of_host(host, &block)
        block.call host
      end

      def with_handler_of_database_name(name, &block)
        check_that_name_is_default name
        block.call name
      end

      def all_databases
        {}
      end

      protected

      def check_that_name_is_default(name)
        fail NotDefaultNameError, "multisite is not active, but #{name} is not 'default'" if name != 'default'
      end
    end
  end
end
