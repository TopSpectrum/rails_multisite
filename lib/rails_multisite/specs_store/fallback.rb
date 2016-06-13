module RailsMultisite

  module SpecsStore

    class Fallback < Base

      def initialize ( variant )

        if variant == 'default'

          @name = 'default'

          resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver

          @spec = resolver.new( ActiveRecord::Base.configurations ).spec Rails.env.to_sym

          @spec.config[ :name ] = @name

          @host_names = @spec.config[ :host_names ]

        else

          @name = 'fallback'

          @spec = spec_for_database @name, config

        end

      end

      #
      # @param host    String - The name of the host. Example: smyers.net or www.smyers.net
      # @return @spec  If the host is in known
      # @return nil    If initialize.variant was 'fail' then fallback.@spec is nil
      def find_by_host ( host )

        return if @host_names && ! @host_names.include?( host )

        @spec

      end

      def find_by_name ( name )

        @spec if name == @name

      end

      def each ( &block )

        block.call @name, @spec

      end

      def include_named? ( name )

        name == @name

      end

      def names

        [ @name ]

      end

      def databases

        { @name => @spec.config }

      end

    end

  end

end
