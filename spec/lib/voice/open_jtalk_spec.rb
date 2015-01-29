require 'spec_helper'
require 'net/http'
require 'uri'
require 'pp'
require 'fileutils'

describe Voice::OpenJtalk do
  subject(:site) { cms_site }

  describe "#build", open_jtalk: true do
    it 'creates wave file by manually specified configuration' do
      talk = Voice::OpenJtalk.new(
        {
          'bin' => SS.config.voice['openjtalk']['bin'],
          'dic' => SS.config.voice['openjtalk']['dic'],
          'voice' => SS.config.voice['openjtalk']['voice'],
          'opts' => SS.config.voice['openjtalk']['opts'],
          'max_length' => SS.config.voice['openjtalk']['max_length'],
          'sox' => SS.config.voice['openjtalk']['sox'] })
      tmp = Tempfile::new(['talk', '.wav'], '/tmp')

      talk.build(site.id, [ 'apple' ], tmp.path)
      expect(tmp.stat.size).to satisfy { |v| v > 20_000 }
    end

    it 'creates wave file by standard configuration' do
      type = SS.config.voice.type
      config = SS.config.voice[type]

      talk = Voice::OpenJtalk.new(config)
      tmp = Tempfile::new(['talk', '.wav'], '/tmp')

      talk.build(site.id, [ 'apple' ], tmp.path)
      expect(tmp.stat.size).to satisfy { |v| v > 20_000 }
    end

    it 'create wav using "test-001.html"' do
      source_file = ::File.new("#{Rails.root}/spec/fixtures/voice/test-001.html")
      html = source_file.read
      texts = Voice::Scraper.new.extract_text html

      type = SS.config.voice.type
      config = SS.config.voice[type]

      talk = Voice::OpenJtalk.new(config)
      tmp = Tempfile::new(['talk', '.wav'], '/tmp')

      talk.build(site.id, texts, tmp.path)
      expect(tmp.stat.size).to satisfy { |v| v > 20_000 }
    end
  end
end
