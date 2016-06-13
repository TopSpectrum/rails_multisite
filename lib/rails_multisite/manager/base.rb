# rubocop:disable AccessorMethodName
module RailsMultisite
  module Manager
    class Base

      def host_name_from_env(env)
        request = Rack::Request.new env
        request['__ws'] || request.host
      end

      def current_host
        config = ActiveRecord::Base.connection_pool.spec.config
        config[:host_names] ? config[:host_names].first : config[:host]
      end

      def each_connection(&_block)
        fail NotImplementedError
      end

      def all_database_names
        fail NotImplementedError
      end

      def current_database_name
        fail NotImplementedError
      end

      def has_database_name?(_name)
        fail NotImplementedError
      end

      def set_current_handler_by_host(_host)
        fail NotImplementedError
      end

      def set_current_handler_by_database_name(_name)
        fail NotImplementedError
      end

      def with_handler_of_host(_host, &_block)
        fail NotImplementedError
      end

      def with_handler_of_database_name(_name, &_block)
        fail NotImplementedError
      end

      def all_databases
        fail NotImplementedError
      end

    end

  end

end
