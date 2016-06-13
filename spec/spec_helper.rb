require 'rubygems'
require 'bundler/setup'

require 'rspec/its'

require 'pry'
require 'pry-rescue'
require 'pry-stack_explorer'
require 'pry-rails'

require 'rails'
require 'active_record'
require 'active_support/core_ext/hash/compact'
require 'rails_multisite'

require 'sqlite3'

require 'spec_support'


ENV[ 'RAILS_ENV' ] ||= 'test'

SPECS_PATH = Pathname.new( __FILE__ ).dirname

DEFAULT_HANDLER = ActiveRecord::Base.connection_handler


RSpec.configure do | config |

  config.before :suite do

    databases = YAML::load File.open 'spec/fixtures/database.yml'

    ActiveRecord::Base.configurations[ 'test' ] = databases[ 'test' ]

  end

end
