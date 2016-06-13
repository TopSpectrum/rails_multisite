require 'lru_redux'
require 'yaml'


module RailsMultisite

  module Configuration

    class ConfigurationError < StandardError; end


    def self.config_filename

      Rails.root.join 'config/multisite.yml'

    end

    #
    #
    # @param config String path to config object
    #TODO write dsl for yaml schema validation
    def self.config_from_file ( filename )

      result = {}

      config = YAML::load_file filename

      multisite = config.delete( 'multisite' ) || {}

      result[ :local ] = config

      result[ :lookup ] = multisite.fetch 'lookup', {}

      fallback_variants = [ 'default', 'fail' ]

      fallback = multisite.fetch 'fallback', fallback_variants.first

      result[ :fallback ] = fallback

      if fallback.is_a?( String ) && ! fallback_variants.include?( fallback )

        raise ConfigurationError, "undefined fallback type: #{ fallback }"

      end

      default_cache = { size: 1000, expires: 0 }

      setted_cache = multisite.fetch( 'cache', {} ).symbolize_keys

      cache = default_cache.merge setted_cache

      result[ :cache ] = cache

      unless ( cache.keys - default_cache.keys ).empty?

        raise ConfigurationError, "unknown cache keys in #{ cache.keys }"

      end

      result

    end

    def self.specs_store_for_config ( config )

      specs_stores = []

      unless config[ :local ].empty?

        specs_stores << RailsMultisite::SpecsStore::Local.new( config[ :local ] )

      end

      unless config[ :lookup ].empty?

        specs_stores << RailsMultisite::SpecsStore::Lookup.new( config[ :lookup ], config )

      end

      unless config[ :fallback ] == 'fail'

        specs_stores << RailsMultisite::SpecsStore::Fallback.new( config[ :fallback ] )

      end

      case specs_stores.size

        when 0 then raise ConfigurationError, 'failed to find any databases with multisite.yml'

        when 1 then specs_stores.first

        else RailsMultisite::SpecsStore::Mixed.new specs_stores

      end

    end

    def self.cache_store_for_config ( config )

      return {} if config[ :lookup ].empty?

      cache = config[ :cache ]

      if cache[ :expires ] > 0

        LruRedux::TTL::ThreadSafeCache.new cache[ :size ], cache[ :expires ]

      else

        LruRedux::ThreadSafeCache.new cache[ :size ]

      end

    end

  end

end
