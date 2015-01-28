module Voice::Converter
  class << self
    public
      def convert(site_id, html, output)
        texts = Voice::Scraper::DEFAULT_INSTANCE.extract_text html

        type = SS.config.voice.type
        config = SS.config.voice[type]

        tts = Voice::TextToSpeechFactory.create(type, config)
        wav_file = Tempfile::new(['talk', '.wav'], '/tmp')
        tts.build(site_id, texts, wav_file.path)

        mp3_file = Tempfile::new(['talk', '.mp3'], '/tmp')
        Voice::WavToMp3.new.convert(wav_file.path, mp3_file.path)

        Fs.binwrite(output, IO.binread(mp3_file.path))
        true
      end
  end
end
