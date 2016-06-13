# coding: utf-8

lib = File.expand_path( '../lib', __FILE__ )
$LOAD_PATH.unshift( lib ) unless $LOAD_PATH.include?( lib )
require 'rails_multisite/version'

Gem::Specification.new do | spec |

  spec.name          = 'rails_multisite'
  spec.version       = RailsMultisite::VERSION
  spec.authors       = [ 'Sam Saffron', 'Michael Smyers' ]
  spec.email         = [ 'sam.saffron@gmail.com', 'michael@topspectrum.com' ]
  spec.summary       = 'Multi tenancy support for Rails'
  spec.description   = 'Multi tenancy support for Rails'
  spec.homepage      = 'https://github.com/TopSpectrum/rails_multisite'
  spec.license       = 'MIT'

  spec.files         = Dir[
    'lib/**/*',
    'README.md',
    'LICENSE.txt'
  ]
  spec.require_paths = [ 'lib' ]


  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_girl_rails'
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'sqlite3'

  spec.add_dependency 'rails'
  spec.add_dependency 'lru_redux'

end
