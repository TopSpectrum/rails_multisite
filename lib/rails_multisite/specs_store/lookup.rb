require 'active_support/core_ext/hash/compact'


module RailsMultisite

  module SpecsStore

    class Lookup < Base

      #TODO: optimize host names retrieval for #each

      BATCH_SIZE = 500

      def initialize(databases, manager_config)
        @pools = []
        databases.each do |name, config|
          spec = spec_for_database name, config
          @pools.push ActiveRecord::ConnectionAdapters::ConnectionPool.new spec
        end

        @spec_cache = Configuration.cache_store_for_config manager_config
      end

      def find_by_host(host)
        query =
          "
          SELECT databases.*
          FROM databases
          LEFT JOIN host_names ON host_names.database_id = databases.id
          WHERE host_names.name = '#{quote_string host}'
          "

        @pools.each do |pool|
          result = exec_query pool, query

          next if result.empty?

          return spec_for_pool_and_row pool, result[0]
        end

        fail "Couldn't find_by_host #{host}"
      end

      def find_by_name(name)
        spec = @spec_cache[name]

        return spec if spec

        query =
          "
          SELECT databases.*
          FROM databases
          WHERE databases.name = '#{quote_string name}'
          "

        @pools.each do |pool|
          result = exec_query pool, query

          next if result.empty?

          return spec_for_pool_and_row pool, result[0]
        end

        fail "Couldn't find_by_name #{name}"
      end

      def each(&block)
        @pools.each do |pool|
          condition = ''

          while true
            query =
              "
              SELECT databases.*
              FROM databases
              #{condition}
              ORDER BY databases.id
              LIMIT #{BATCH_SIZE}
              "

            result = exec_query pool, query

            result.each do |row|
              spec = spec_for_pool_and_row pool, row
              block.call row['name'], spec
            end

            break if result.rows.size < BATCH_SIZE

            condition = "WHERE databases.id > #{result.last['id']}"

          end
        end
      end

      def include_named?(name)
        return true if @spec_cache[name]

        query =
          "
          SELECT databases.*
          FROM databases
          WHERE databases.name = '#{quote_string name}'
          "

        @pools.any? do |pool|
          result = exec_query pool, query
          next if result.empty?
          spec_for_pool_and_row pool, result[0]
          return true
        end

        return false
      end

      def names
        @pools.map do |pool|
          result = exec_query pool, "SELECT databases.name FROM databases"
          result.rows
        end.flatten
      end

      def databases
        result = {}
        @pools.each do |pool|
          databases = exec_query pool, "SELECT databases.* FROM databases"
          databases.each do |database|
            result[database['name']] = database
          end
        end
        result
      end

      protected

      define_method :quote_string, ActiveRecord::ConnectionAdapters::Quoting.instance_method(:quote_string)

      def exec_query(pool, query)
        pool.with_connection { |connection| connection.exec_query query }
      end

      def spec_for_pool_and_row(pool, row)
        name = row['name']

        spec = @spec_cache[name]

        return spec if spec

        query =
          "
          SELECT host_names.name
          FROM host_names
          WHERE host_names.database_id = #{row['id']}
          "

        result = exec_query pool, query

        host_names = result.rows.flatten

        p "Looking for name='#{name}'"
        if name.to_s == ""
          p "No NAME !"
          puts "#" * 30
          puts caller
          puts "#" * 30
          p "No NAME !"
        end
        spec = spec_for_database name, row.compact

        spec.config[:host_names] = host_names

        @spec_cache[name] = spec

        return spec

      end
    end
  end
end
