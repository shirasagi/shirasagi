require 'spec_helper'
require 'models/voice/test_http_server'

describe Voice::VoiceFile do
  describe '#find_or_create_by_url' do
    context "when valid site is given" do
      random_string = rand(0x100000000).to_s(36)
      subject(:site) { cms_site }
      subject { Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string) }

      it { should_not be_nil }
      its(:class) { should be Voice::VoiceFile }
      its(:id) { should be_a(BSON::ObjectId) }
      its(:path) { should eq "/#{random_string}" }
      its(:url) { should eq "http://#{site.domain}/" + random_string }
      its(:page_identity) { should be_nil }
      its(:lock_until) { should eq Time.at(0) }
      its(:error) { should be_nil }
      its(:has_error) { should eq 0 }
      its(:age) { should eq 0 }
      its(:file) { should match %r</voice_files/[1-9]/[0-9a-f]{2}/[0-9a-f]{2}/_/> }
    end

    context "when invalid site is given" do
      random_string = rand(0x100000000).to_s(36)
      subject { Voice::VoiceFile.find_or_create_by_url("http://invalid-site-#{random_string}/" + random_string) }

      it { should be_nil }
    end
  end

  describe '#acquire_lock' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    locked_voice_file = nil
    expected_lock_until = nil
    before(:all) do
      site = cms_site
      voice_file = Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string)
      locked_voice_file = Voice::VoiceFile.acquire_lock(voice_file)
      expected_lock_until  = Time.now
    end
    subject { locked_voice_file }

    it { should_not be_nil }
    its(:class) { should be Voice::VoiceFile }
    its(:lock_until) { should be >= expected_lock_until }
  end

  context 'when acquire_lock call twice' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    locked_voice_file = nil
    before(:all) do
      site = cms_site
      voice_file = Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string)
      # lock twice
      Voice::VoiceFile.acquire_lock(voice_file)
      locked_voice_file = Voice::VoiceFile.acquire_lock(voice_file)
    end
    subject { locked_voice_file }
    it { should be_nil }
  end

  describe '#release_lock' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    released_voice_file = nil
    before(:all) do
      site = cms_site
      voice_file = Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string)
      locked_voice_file = Voice::VoiceFile.acquire_lock(voice_file)
      released_voice_file = Voice::VoiceFile.release_lock(locked_voice_file)
    end
    subject { released_voice_file }

    it { should_not be_nil }
    its(:class) { should be Voice::VoiceFile }
    its(:lock_until) { should eq Time.at(0) }
  end

  context 'when error is given, has_error is set automatically' do
    random_string = rand(0x100000000).to_s(36)
    subject(:site) { cms_site }
    subject(:voice_file) { Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string) }
    subject {
      voice_file.error = "has error"
      voice_file.save!
      voice_file
    }

    it { should_not be_nil }

    describe "#has_error" do
      its(:error) { should eq "has error" }
      its(:has_error) { should eq 1 }
    end

    describe "#search" do
      count = nil
      before(:all) do
        count = Voice::VoiceFile.search({ :has_error => 1 }).count
      end
      it { expect(count).to be >= 1 }
    end
  end

  describe '#download' do
    port = 33_190
    http_server = Voice::TestHttpServer.new(port)

    before :all  do
      http_server.start
    end

    after :all  do
      http_server.stop
    end

    subject(:voice_site) do
      Cms::Site.find_or_create_by(name: "VoiceSite", host: "test-voice", domains: [ "localhost:#{port}" ])
    end

    context "when downloads page" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}"
        Voice::VoiceFile.find_or_create_by_url(url)
      end

      it { should_not be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not respond etag" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", etag: nil)
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?etag=nil"
        Voice::VoiceFile.find_or_create_by_url(url)
      end

      it { should_not be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not respond last_modified" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", last_modified: nil)
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?last_modified=nil"
        Voice::VoiceFile.find_or_create_by_url(url)
      end

      it { should_not be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not either respond etag or last_modified" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before :all  do
        http_server.add_redirect("/#{path}", "/test-001.html")
        http_server.add_options("/#{path}", etag: nil, last_modified: nil)
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?etag=nil&last_modified=nil"
        Voice::VoiceFile.find_or_create_by_url(url)
      end

      it { should_not be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end
  end
end
