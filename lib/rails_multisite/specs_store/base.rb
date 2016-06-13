module RailsMultisite

  module SpecsStore

    class Base

      def find_by_host ( host )

        raise NotImplementedError

      end

      def find_by_name ( name )

        raise NotImplementedError

      end

      def each ( &block )

        raise NotImplementedError

      end

      def include_named? ( name )

        raise NotImplementedError

      end

      def names

        raise NotImplementedError

      end

      def databases

        raise NotImplementedError

      end

      protected

      #
      # For a given database config (hash), returns a database config that we can use
      # to connect to a database.
      # @return ConnectionSpecification or nil
      def spec_for_database ( name, config )

        begin
          resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new 'key' => config
        rescue => ex
            puts "Exception in spec_for_database #{ex}"
            puts "Backtrace:\n\t#{ex.backtrace.join("\n\t")}"         
          raise
        end
        spec = resolver.spec :key

        spec.config[ :name ] = name

        spec

      end

    end

  end

end
