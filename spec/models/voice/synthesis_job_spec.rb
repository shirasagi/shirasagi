require 'spec_helper'
require 'json'
require 'models/voice/test_http_server'

describe Voice::SynthesisJob do
  describe '#call_async', open_jtalk: true do
    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      expected_args = []
      expected_priority = 0
      before :all  do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s
        expected_args = [ id.to_s ]
        expected_priority = Time.now.to_i
      end

      after :all  do
        http_server.stop
      end

      subject { Job::Model.find_by(pool: 'voice_synthesis') rescue nil }

      it { should_not be_nil }
      its(:class_name) { should eq 'Voice::SynthesisJob' }
      its(:args) { should eq expected_args }
      its(:priority) { should be_within(30).of(expected_priority) }
      it { expect(subject.class_name.constantize).to be Voice::SynthesisJob }
    end

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        system(cmd)
      end

      after(:all) do
        http_server.stop
      end

      subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
      it { should be_nil }
      it { expect(Voice::VoiceFile.where(url: url).count).to be >= 1 }
    end

    context 'when get 400' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?status_code=400&_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        system(cmd)
      end

      after(:all) do
        http_server.stop
      end

      subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
      it { should be_nil }
      it { expect(Voice::VoiceFile.where(url: url).count).to eq 0 }
    end

    context 'when get 404' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?status_code=404&_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        system(cmd)
      end

      after(:all) do
        http_server.stop
      end

      subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
      it { should be_nil }
      it { expect(Voice::VoiceFile.where(url: url).count).to eq 0 }
    end

    context 'when get 500' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?status_code=500&_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        system(cmd)
      end

      after(:all) do
        http_server.stop
      end

      subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
      it { should be_nil }
      it { expect(Voice::VoiceFile.where(url: url).count).to eq 0 }
    end

    context 'when server timed out' do
      port = 33_190
      http_server = Voice::TestHttpServer.new(port)
      url = "http://localhost:#{port}/test-001.html?wait=10&_=#{rand(0x100000000).to_s(36)}"
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.start
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        system(cmd)
      end

      after(:all) do
        http_server.stop
      end

      subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
      it { should be_nil }
      it { expect(Voice::VoiceFile.where(url: url).count).to eq 0 }
    end
  end

  describe '#call', open_jtalk: true do
    port = 33_190
    http_server = Voice::TestHttpServer.new(port)

    before(:all) do
      http_server.start
    end

    after(:all) do
      http_server.stop
    end

    subject(:site) { cms_site }

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      url = "http://localhost:#{port}/test-001.html?_=#{rand(0x100000000).to_s(36)}"

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to change {
          voice_file.exists?
        }.from(false).to(true)
      end
    end

    context 'when get 404' do
      url = "http://localhost:#{port}/test-001.html?status_code=404&_=#{rand(0x100000000).to_s(36)}"

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates dows not voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to raise_error OpenURI::HTTPError
        expect(Voice::VoiceFile.where(id: voice_file.id).count).to eq 0
      end
    end

    context 'when server timed out' do
      url = "http://localhost:#{port}/test-001.html?wait=104&_=#{rand(0x100000000).to_s(36)}"

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates dows not voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to raise_error TimeoutError
        expect(Voice::VoiceFile.where(id: voice_file.id).count).to eq 0
      end
    end
  end
end
