require 'spec_helper'
require 'bson'

describe Voice::VoiceFile do
  describe '#find_or_create_by_url' do
    random_string = rand(0x100000000).to_s(36)
    subject(:site) { cms_site }
    subject { Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string) }

    it { should_not be_nil }
    its(:id) { should be_a(BSON::ObjectId) }
    its(:path) { should eq "/#{random_string}" }
    its(:url) { should eq "http://#{site.domain}/" + random_string }
    its(:last_modified) { should be_nil }
    its(:lock_until) { should eq Time.at(0) }
    its(:error) { should be_nil }
    its(:has_error) { should eq 0 }
    its(:age) { should eq 0 }
    its(:file) { should match %r</voice_files/[1-9]/[0-9a-f]{2}/[0-9a-f]{2}/_/> }
  end

  describe '#acquire_lock' do
    random_string = rand(0x100000000).to_s(36)
    site = nil
    locked_voice_file = nil
    expected_lock_until = nil
    before(:all) do
      site = cms_site
      voice_file = Voice::VoiceFile.find_or_create_by_url("http://#{site.domain}/" + random_string)
      locked_voice_file = Voice::VoiceFile.acquire_lock(voice_file.id)
      expected_lock_until  = Time.now
    end
    subject { locked_voice_file }

    it { should_not be_nil }
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
      Voice::VoiceFile.acquire_lock(voice_file.id)
      locked_voice_file = Voice::VoiceFile.acquire_lock(voice_file.id)
    end
    subject { locked_voice_file }
    it { should be_nil }
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
end
