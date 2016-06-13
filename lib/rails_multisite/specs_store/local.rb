module RailsMultisite

  module SpecsStore

    class Local < Base

      #
      #
      # Pass in some config. Since the Local strategy is built on startup and is immutable, all database config info
      # is defined at time of construction.
      def initialize ( databases )

        @spec_hash = {}

        @host_spec_cache = {}

        @databases = databases

        @databases.each do | name, config |

          spec = spec_for_database name, config

          @spec_hash[ name ] = spec

          next unless spec.config[ :host_names ]

          spec.config[ :host_names ].each do | host |

            @host_spec_cache[ host ] = spec

          end

        end

      end

      def find_by_host ( host )

        @host_spec_cache[ host ]

      end

      def find_by_name ( name )

        @spec_hash[ name ]

      end

      def each ( &block )

        @spec_hash.each &block

      end

      def include_named? ( name )

        @spec_hash.has_key? name

      end

      def names

        @spec_hash.keys

      end

      def databases

        @databases

      end

    end

  end

end
