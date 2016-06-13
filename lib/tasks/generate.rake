namespace :multisite do

  namespace :generate do

    desc 'generate multisite config file (if missing)'
    task config: :environment do

      filename =  RailsMultisite::Configuration.config_filename

      if File.exists?( filename )

        puts "Config is already generated at #{ RailsMultisite::Configuration.config_filename }"

      else

        puts "Generated config file at #{ RailsMultisite::Configuration.config_filename }"

        File.open( filename, 'w' ) do | f |

          f.write <<-CONFIG
  # site_name:
  #   adapter: postgresql
  #   database: db_name
  #   host: localhost
  #   pool: 5
  #   timeout: 5000
  #   db_id: 1           # optionally include other settings you need
  #   host_names:
  #     - www.mysite.com
  #     - www.anothersite.com
  CONFIG

        end

      end

    end

  end

end
