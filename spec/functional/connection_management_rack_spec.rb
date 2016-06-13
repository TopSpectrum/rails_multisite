require 'rack/test'

RSpec.describe RailsMultisite::ConnectionManagement do

  subject( :klass ) { RailsMultisite::ConnectionManagement }

  before( :each ) { clear_state }
  
  
  include Rack::Test::Methods

  def app

    klass.load_settings! 'spec/fixtures/two_dbs.yml'

    Rack::Builder.new do

      use RailsMultisite::ConnectionManagement

      map '/html' do

        run proc { | env |

          [ 200, { 'Content-Type' => 'text/html' }, "<html><BODY><h1>Hi</h1></BODY>\n \t</html>" ] 

        }

      end

    end

  end

  describe 'as middleware' do

    it 'returns 200 for valid site' do

      get 'http://second.localhost/html'

      expect( last_response ).to be_ok

    end

    it 'returns 200 for valid main site' do

      get 'http://default.localhost/html'

      expect( last_response ).to be_ok

    end

    it 'returns 404 for invalid site' do

      get 'http://unknown.localhost/html'

      expect( last_response ).to be_not_found

    end

  end

end

