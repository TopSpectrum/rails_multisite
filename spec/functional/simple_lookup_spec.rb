RSpec.describe 'simple lookup example' do

  subject( :klass ) { RailsMultisite::ConnectionManagement }

  before( :each ) { clear_state }

  subject( :with_connection ) { klass.method :with_connection }


  class Person < ActiveRecord::Base
  end

  class Database < ActiveRecord::Base
  end

  class HostName < ActiveRecord::Base
  end

  def toggle_tables ( bool )

    toogle_table_in_database 'lookup', 'databases', bool && 'name, adapter, database'

    toogle_table_in_database 'lookup', 'host_names', bool && 'database_id INTEGER, name'

    toogle_table_in_database 'lookedup', 'people', bool && 'db'

    if bool

      with_connection.call 'lookup' do

        database = Database.create name: 'lookedup_db', adapter: 'sqlite3', database: 'tmp/lookedup.test'

        HostName.create database_id: database.id, name: 'lookedup_host'

      end

      with_connection.call 'lookedup' do

        Person.create db: 'lookedup'

      end

    end

  end
  

  before { klass.load_settings! 'spec/fixtures/lookup.yml' }

  before { toggle_tables true }

  after { toggle_tables false }

#  it( '.all_dbs' ) { expect( klass.all_dbs ).to eq [ 'lookup', 'lookedup', 'lookedup_db' ] }

  it( '.has_db?' ) { expect( klass.has_db? 'lookedup_db' ).to be true }

  {

    host: 'lookedup_host',
    db: 'lookedup_db'

  }.each do | selector, value |

    context ".establish_connection #{ selector }:" do

      before { klass.establish_connection selector => value }

      it( '.current_db' ) { expect( klass.current_db ).to eq 'lookedup_db' }
      
      it( '.current_hostname' ) { expect( klass.current_hostname ).to eq 'lookedup_host' }

      it( 'person exists' ) { expect( Person.first.db ).to eq 'lookedup' }

    end

  end

  it '.each_connection' do

    expect { | block | klass.each_connection &block }.to yield_control.exactly( 3 ).times

  end

end
