require 'spec_helper'

describe Voice::WavToMp3 do
  describe "#convert", open_jtalk: true do
    it 'creates mp3 file from File Object' do
      input_file = ::File.new("#{Rails.root}/spec/fixtures/voice/voice-disabled.wav")
      output_file = Tempfile::new(['talk', '.mp3'], '/tmp')

      Voice::WavToMp3.new.convert(input_file, output_file)
      expect(output_file.stat.size).to satisfy { |v| v > 10_000 }
    end

    it 'creates mp3 file from String File Path' do
      input_file = ::File.new("#{Rails.root}/spec/fixtures/voice/voice-disabled.wav")
      input_file = input_file.path
      output_file = Tempfile::new(['talk', '.mp3'], '/tmp')

      Voice::WavToMp3.new.convert(input_file, output_file.path)
      expect(output_file.stat.size).to satisfy { |v| v > 10_000 }
    end
  end
end
