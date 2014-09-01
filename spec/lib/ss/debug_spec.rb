#require_relative '../../../lib/ss/debug'

describe SS::Debug do
  # SS::Debug.dump(data, lev = 1)
  # data will accept type of String, Hash, Array and Fixnum
  subject { SS::Debug }

  describe '.dump' do
    it 'receives String "test", returns "test <String>"' do
      target = 'test'
      result = subject.dump(target, 2)
      expect(result.class).to eq String
      expect(result).to eq 'test <String>'
    end

    it 'receives Array data, returns "<Array> [...]" format string' do
      result = subject.dump([1, 2, 3], 2)
      # manipulate String to WYSIWYG
      expectied_result = <<-EOF.gsub(/^\s+\|/, '').gsub(/\n$/, '')
        |<Array> [
        |    0 \t=> 1 <Fixnum>
        |    1 \t=> 2 <Fixnum>
        |    2 \t=> 3 <Fixnum>
        |  ]
      EOF
      expect(result.class).to eq String
      expect(result).to eq expectied_result
    end

    it 'receives Hash data, returns "<Hash> {...}" format string' do
      result = subject.dump({a: 1, b: '2', c: [10]}, 2)
      expectied_result = <<-EOF.gsub(/^\s+\|/, '').gsub(/\n$/, '')
        |<Hash> {
        |    a \t=> 1 <Fixnum>
        |    b \t=> 2 <String>
        |    c \t=> <Array> [
        |      0 \t=> 10 <Fixnum>
        |    ]
        |  }
      EOF
      expect(result.class).to eq String
      expect(result).to eq expectied_result
    end

    it 'receives 1, returns "1 <Fixnum>"' do
      result = subject.dump(1, 2)
      expectied_result = <<-EOF.gsub(/^\s+\|/, '').gsub(/\n$/, '')
        |1 <Fixnum>
      EOF
      expect(result.class).to eq String
      expect(result).to eq expectied_result
    end
  end
end
