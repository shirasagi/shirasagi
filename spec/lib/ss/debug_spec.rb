module SS; end

require_relative '../../../lib/ss/debug'

describe SS::Debug do
  # SS::Debug.dump(data, lev = 1)
  # data will accept type of String, Hash, Array and Fixnum
  subject { SS::Debug }

  describe '.debug' do
    it 'receives String "test", returns "test <String>"'

    it 'receives Array data, returns "<Array> [...]" format string'

    it 'receives Hash data, returns "<Hash> {...}" format string'

    it 'receives 1, returns "1 <Fixnum>"'
  end
end
