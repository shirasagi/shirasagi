module Voice::Converter
  class << self
    def convert(site_id, html, output)
      texts = Voice::Scraper::DEFAULT_INSTANCE.extract_text html

      type = SS.config.voice.type
      config = SS.config.voice[type]

      tts = Voice::TextToSpeechFactory.create(type, config)
      Dir.mktmpdir do |tmpdir|
        wav_file = ::File.join(tmpdir, ::Dir::Tmpname.make_tmpname(["voice", ".wav"], nil))
        tts.build(site_id, texts, wav_file)

        mp3_file = ::File.join(tmpdir, ::Dir::Tmpname.make_tmpname(["voice", ".mp3"], nil))
        Voice::WavToMp3.new.convert(wav_file, mp3_file)

        Fs.binwrite(output, IO.binread(mp3_file))
        true
      end
    end
  end
end
