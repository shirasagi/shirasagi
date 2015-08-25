require 'spec_helper'

describe Voice::File, http_server: true do
  http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "voice")

  describe '#find_or_create_by_url' do
    context "when valid site is given" do
      random_string = rand(0x100000000).to_s(36)
      let(:site) { cms_site }
      subject { described_class.find_or_create_by_url("http://#{site.domain}/" + random_string) }

      it { is_expected.not_to be_nil }
      its(:class) { is_expected.to be described_class }
      its(:id) { is_expected.to be_a(BSON::ObjectId) }
      its(:path) { is_expected.to eq "/#{random_string}" }
      its(:url) { is_expected.to eq "http://#{site.domain}/" + random_string }
      its(:page_identity) { is_expected.to be_nil }
      its(:lock_until) { is_expected.to eq Time.zone.at(0) }
      its(:error) { is_expected.to be_nil }
      its(:has_error) { is_expected.to eq 0 }
      its(:age) { is_expected.to eq 0 }
      its(:file) { is_expected.to match %r</voice_files/[1-9]/[0-9a-f]{2}/[0-9a-f]{2}/_/> }
    end

    context "when invalid site is given" do
      random_string = rand(0x100000000).to_s(36)
      subject { described_class.find_or_create_by_url("http://invalid-site-#{random_string}/" + random_string) }

      it { is_expected.to be_nil }
    end
  end

  describe '#acquire_lock' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    locked_voice_file = nil
    expected_lock_until = nil
    before(:all) do
      site = cms_site
      voice_file = described_class.find_or_create_by_url("http://#{site.domain}/" + random_string)
      locked_voice_file = described_class.acquire_lock(voice_file)
      expected_lock_until = Time.zone.now
    end
    subject { locked_voice_file }

    it { is_expected.not_to be_nil }
    its(:class) { is_expected.to be described_class }
    its(:lock_until) { is_expected.to be >= expected_lock_until }
  end

  context 'when acquire_lock call twice' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    locked_voice_file = nil
    before(:all) do
      site = cms_site
      voice_file = described_class.find_or_create_by_url("http://#{site.domain}/" + random_string)
      # lock twice
      described_class.acquire_lock(voice_file)
      locked_voice_file = described_class.acquire_lock(voice_file)
    end
    subject { locked_voice_file }
    it { is_expected.to be_nil }
  end

  describe '#release_lock' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    released_voice_file = nil
    before(:all) do
      site = cms_site
      voice_file = described_class.find_or_create_by_url("http://#{site.domain}/" + random_string)
      locked_voice_file = described_class.acquire_lock(voice_file)
      released_voice_file = described_class.release_lock(locked_voice_file)
    end
    subject { released_voice_file }

    it { is_expected.not_to be_nil }
    its(:class) { is_expected.to be described_class }
    its(:lock_until) { is_expected.to eq Time.zone.at(0) }
  end

  context 'when error is given, has_error is set automatically' do
    random_string = rand(0x100000000).to_s(36)
    let(:site) { cms_site }
    let(:voice_file) { described_class.find_or_create_by_url("http://#{site.domain}/" + random_string) }
    subject do
      voice_file.error = "has error"
      voice_file.save!
      voice_file
    end

    it { is_expected.not_to be_nil }

    describe "#has_error" do
      its(:error) { is_expected.to eq "has error" }
      its(:has_error) { is_expected.to eq 1 }
    end

    describe "#search" do
      count = nil
      before(:all) do
        count = described_class.search({ :has_error => 1 }).count
      end
      it { expect(count).to be >= 1 }
    end
  end

  describe '#download' do
    let(:voice_site) do
      Cms::Site.find_or_create_by(name: "VoiceSite", host: "test-voice", domains: [ "127.0.0.1:33190" ])
    end

    context "when downloads page" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html"
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}"
        described_class.find_or_create_by_url(url)
      end

      it { is_expected.not_to be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not respond etag" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", etag: nil
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?etag=nil"
        described_class.find_or_create_by_url(url)
      end

      it { is_expected.not_to be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not respond last_modified" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", last_modified: nil
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?last_modified=nil"
        described_class.find_or_create_by_url(url)
      end

      it { is_expected.not_to be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end

    context "when server does not either respond etag or last_modified" do
      path = "#{rand(0x100000000).to_s(36)}.html"

      before do
        http.options real_path: "/test-001.html", etag: nil, last_modified: nil
      end

      subject(:voice_file) do
        url = "http://#{voice_site.domain}/#{path}?etag=nil&last_modified=nil"
        described_class.find_or_create_by_url(url)
      end

      it { is_expected.not_to be_nil }

      it "downloads page" do
        voice_file.download
        expect(voice_file.cached_page).to_not be_nil
        expect(voice_file.cached_page.html).to_not be_nil
        expect(voice_file.cached_page.page_identity).to_not be_nil
      end
    end
  end
end
