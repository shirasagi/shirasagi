require 'spec_helper'
require 'json'
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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      expected_args = []
      expected_priority = 0
      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        Voice::SynthesisJob.call_async id.to_s
        expected_args = [ id.to_s ]
        expected_priority = Time.now.to_i
      end

      describe "job" do
        subject { Job::Model.find_by(pool: 'voice_synthesis') rescue nil }
        it { should_not be_nil }
        its(:class_name) { should eq 'Voice::SynthesisJob' }
        its(:args) { should eq expected_args }
        its(:priority) { should be_within(30).of(expected_priority) }
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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        Voice::SynthesisJob.call_async id.to_s
        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 400)
        Voice::SynthesisJob.call_async id.to_s
        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 404)
        Voice::SynthesisJob.call_async id.to_s

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 500)
        Voice::SynthesisJob.call_async id.to_s
        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", wait: wait)
        Voice::SynthesisJob.call_async id.to_s
        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

      after(:all) do
        http_server.release_wait
      end

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
      id = Voice::VoiceFile.find_or_create_by(site_id: 1, url: url).id

      before(:all) do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", last_modified: nil)
        Voice::SynthesisJob.call_async id.to_s
        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
        system(cmd)
      end

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
      # puts "stopping web server"
      http_server.stop
      # puts "stopped web server"
    end

    subject(:site) { cms_site }

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}"

      before :all  do
        # puts '[enter] when synthesize from file "fixtures/voice/test-001.html"'
        http_server.add_redirect("/#{path}", "/test-001.html")
      end

      # after :all  do
      #   puts '[leave] when synthesize from file "fixtures/voice/test-001.html"'
      # end

      subject(:voice_file) { Voice::VoiceFile.find_or_create_by(site_id: site.id, url: url) }

      it "creates voice file" do
        expect {
          Voice::SynthesisJob.new.call(voice_file.id)
        }.to change {
          voice_file.exists?
        }.from(false).to(true)

        voice_file.reload
        expect(voice_file.same_identity?).to be_true
        expect(voice_file.latest?).to be_true
        expect(voice_file.error).to be_nil
        expect(voice_file.has_error).to eq 0
        expect(voice_file.age).to be > 0
      end
    end

    context 'when get 404' do
      path = "#{rand(0x100000000).to_s(36)}.html"
      url = "http://localhost:#{port}/#{path}?status_code=404"

      before :all  do
        # puts '[enter] when get 404'
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", status_code: 404)
      end

      # after :all  do
      #   puts '[leave] when get 404'
      # end

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
        # puts '[enter] when server timed out'
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", wait: wait)
      end

      after :all  do
        # puts '[leave] when server timed out'
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
