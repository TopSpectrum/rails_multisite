require 'rails_multisite/version'
require 'rails_multisite/specs_store/base'
require 'rails_multisite/specs_store/local'
require 'rails_multisite/specs_store/lookup'
require 'rails_multisite/specs_store/fallback'
require 'rails_multisite/specs_store/mixed'
require 'rails_multisite/configuration'
require 'rails_multisite/manager/base'
require 'rails_multisite/manager/dummy'
require 'rails_multisite/manager/real'
require 'rails_multisite/connection_management'
require 'tasks/tasks'
require 'rails_multisite/railtie'


module RailsMultisite

  LOOKUPS_MIGRATIONS_PATH = File.join( File.dirname( __FILE__ ), 'migrations' )

end
