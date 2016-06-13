RSpec.describe RailsMultisite::Configuration do

  subject( :klass ) { RailsMultisite::Configuration }


  describe '.config_from_file' do

    subject( :config_from_file ) { klass.method :config_from_file }


    [ 'full', 'local' ].each do | filename |

      context "#{ filename } basic" do

        subject( :config ) { config_from_file.call SPECS_PATH.join( "configs/#{ filename }.yml" ) }

        it { expect( config ).to be_instance_of Hash }

        it { expect( config.keys ).to eq [ :local, :lookup, :fallback, :cache ] }

        it { expect( config[ :cache ].keys ).to eq [ :size, :expires ] }

      end

    end

    context 'full details' do

      subject( :config ) { config_from_file.call SPECS_PATH.join 'configs/full.yml' }

      it { expect( config[ :local ].size ).to eq 2 }

      it { expect( config[ :lookup ].size ).to eq 1 }

      it { expect( config[ :fallback ] ).to eq 'default' }

    end

    context 'local details' do

      subject( :config ) { config_from_file.call SPECS_PATH.join 'configs/local.yml' }

      it { expect( config[ :local ].size ).to eq 2 }

      it { expect( config[ :lookup ] ).to be_empty }

      it { expect( config[ :fallback ] ).to eq 'fail' }

    end

  end

end
