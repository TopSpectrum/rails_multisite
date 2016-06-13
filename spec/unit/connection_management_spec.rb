RSpec.describe RailsMultisite::ConnectionManagement do

  subject( :klass ) { RailsMultisite::ConnectionManagement }

  before( :each ) { clear_state }


=begin
  context 'default' do

    its( :all_dbs ) { is_expected.to eq [ 'default' ] }

    context 'established' do

      before { klass.establish_connection db: 'default' }

      its( :current_db ) { is_expected.to eq 'default' }
      
      its( :current_hostname ) { is_expected.to eq 'default.localhost' }

    end

  end

  context 'two dbs' do

    before { klass.load_settings! 'spec/fixtures/two_dbs.yml' }

    its( :all_dbs ) { is_expected.to eq ['second', 'default'] }

    context 'established' do

      before { klass.establish_connection db: 'second' }

      its( :current_db ) { is_expected.to eq 'second' }

      its( :current_hostname ) { is_expected.to eq 'second.localhost' }

    end

  end
=end

  describe '.with_connection' do

    subject( :with_connection ) { RailsMultisite::ConnectionManagement.method :with_connection }


    class Person < ActiveRecord::Base
    end


    before { klass.load_settings! 'spec/fixtures/two_dbs.yml' }

    let( :database_names ) { klass.all_dbs }

    def toogle_person_table ( bool )

      database_names.each do | name |

        toogle_table_in_database name, 'people', bool && 'db'

      end

    end

    before { toogle_person_table true }

    after { toogle_person_table false }

    it 'partitions data correctly' do

      threads = []

      5.times do

        threads += database_names.map do | name |

          Thread.new do

            with_connection.call name do

              Person.create! db: name

            end

          end

        end

      end

      threads.each &:join

      database_names.each do | name |

        with_connection.call name do

          persons = Person.order( :id ).to_a.map { | person | [ person.id, person.db ] }

          expect( persons ).to eq ( 1..5 ).map { | id | [ id, name ] }

        end

      end

    end

  end

end
