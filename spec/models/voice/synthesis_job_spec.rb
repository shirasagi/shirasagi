require 'spec_helper'
require 'models/voice/test_http_server'

describe Voice::SynthesisJob do
  describe '#call_async', open_jtalk: true do
    port = 33_190
    http_server = Voice::TestHttpServer.new(port)

    before :all  do
      http_server.start
    end

    after :all  do
      http_server.stop
    end

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }

      before :all do
        http_server.add_redirect("/#{path}", "/test-001.html")
      end

      it { expect(job).not_to be_nil }

      describe "job" do
        subject { Job::Model.find_by(pool: 'voice_synthesis') rescue nil }
        it { should_not be_nil }
        its(:class_name) { should eq 'Voice::SynthesisJob' }
        its(:args) { should eq [ id.to_s ] }
        its(:priority) { should be_within(30).of(Time.now.to_i) }
        it { expect(subject.class_name.constantize).to be Voice::SynthesisJob }
      end

      describe "voice_file" do
        subject { Voice::VoiceFile.find_by(url: url) rescue nil }
        it { should_not be_nil }
        its(:lock_until) { should eq Time.at(0) }
        its(:error) { should be_nil }
        its(:has_error) { should eq 0 }
        its(:age) { should be >= 0 }
      end
    end

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be_truthy }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Voice::VoiceFile.find_by(url: url) rescue nil }
        it { should_not be_nil }
        its(:lock_until) { should eq Time.at(0) }
        its(:error) { should be_nil }
        its(:has_error) { should eq 0 }
        its(:age) { should be > 0 }
      end
    end

    context 'when get 400' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?status_code=400"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 400)
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be false }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Model.find_by(url: url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when get 404' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?status_code=404"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 404)
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be_falsey }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Model.find_by(url: url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when get 500' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?status_code=500"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 500)
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be_falsey }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Model.find_by(url: url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when server timed out' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      wait = SS.config.voice.download['timeout_sec'] + 5
      url = "http://localhost:#{port}/#{path}?wait=#{wait}"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", wait: wait)
      end

      after(:all) do
        http_server.release_wait
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be_falsey }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Model.find_by(url: url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when server does not respond last_modified' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?last_modified=nil"
      let(:item) { Voice::VoiceFile.find_or_create_by(site_id: cms_site.id, url: url) }
      let(:id) { item.id }
      let(:job) { Voice::SynthesisJob.call_async id.to_s }
      let(:cmd) { "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1" }

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", last_modified: nil)
      end

      it { expect(job).not_to be_nil }
      it { expect(system(cmd)).to be_truthy }

      describe "job" do
        subject { Job::Model.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Voice::VoiceFile.find_by(url: url) rescue nil }
        it { should_not be_nil }
        its(:page_identity) { expect(subject.page_identity).to_not be_nil }
        its(:lock_until) { should eq Time.at(0) }
        its(:error) { should be_nil }
        its(:has_error) { should eq 0 }
        its(:age) { should be > 0 }
      end
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
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
      end

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to change {
          voice_file.exists?
        }.from(false).to(true)

        voice_file.reload
        expect(voice_file.same_identity?).to be_truthy
        expect(voice_file.latest?).to be_truthy
        expect(voice_file.error).to be_nil
        expect(voice_file.has_error).to eq 0
        expect(voice_file.age).to be > 0
      end
    end

    context 'when get 404' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?status_code=404"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 404)
      end

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates dows not voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to raise_error OpenURI::HTTPError
        expect(Voice::VoiceFile.where(id: voice_file.id).count).to eq 0
      end
    end

    context 'when server timed out' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      wait = SS.config.voice.download['timeout_sec'] + 5
      url = "http://localhost:#{port}/#{path}?wait=#{wait}"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", wait: wait)
      end

      after :all  do
        http_server.release_wait
      end

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
