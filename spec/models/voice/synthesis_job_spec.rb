require 'spec_helper'

describe Voice::SynthesisJob, http_server: true do
  http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "voice")

  describe '#call_async', open_jtalk: true do
    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
      end

      before do
        http.options real_path: "/test-001.html"
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }

      describe "job" do
        subject { Job::Task.find_by(pool: 'voice_synthesis') rescue nil }
        it { is_expected.not_to be_nil }
        its(:class_name) { is_expected.to eq 'Voice::SynthesisJob' }
        its(:args) { is_expected.to eq [ @item.id.to_s ] }
        its(:priority) { is_expected.to be_within(30).of(Time.zone.now.to_i) }
        it { expect(subject.class_name.constantize).to be Voice::SynthesisJob }
      end

      describe "voice_file" do
        subject { Voice::File.find_by(url: @url) rescue nil }
        it { is_expected.not_to be_nil }
        its(:lock_until) { is_expected.to eq Time.zone.at(0) }
        its(:error) { is_expected.to be_nil }
        its(:has_error) { is_expected.to eq 0 }
        its(:age) { is_expected.to be >= 0 }
      end
    end

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      before(:all) do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html"
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { is_expected.to be_nil }
      end

      describe "voice_file" do
        subject { Voice::File.find_by(url: @url) rescue nil }
        it { is_expected.not_to be_nil }
        its(:lock_until) { is_expected.to eq Time.zone.at(0) }
        its(:error) { is_expected.to be_nil }
        its(:has_error) { is_expected.to eq 0 }
        its(:age) { is_expected.to be > 0 }
      end
    end

    context 'when get 400' do
      before(:all) do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}?status_code=400"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html", status_code: 400
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Task.find_by(url: @url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when get 404' do
      before(:all) do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}?status_code=404"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html", status_code: 404
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Task.find_by(url: @url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when get 500' do
      before(:all) do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}?status_code=500"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html", status_code: 500
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Task.find_by(url: @url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when server timed out' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @wait = SS.config.voice.download['timeout_sec'] + 5
        @url = "http://127.0.0.1:33190/#{@path}?wait=#{@wait}"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html", wait: @wait
      end

      after(:all) do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Job::Task.find_by(url: @url) rescue nil }
        it { should be_nil }
      end
    end

    context 'when server does not respond last_modified' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}?last_modified=nil"

        @item = Voice::File.find_or_create_by(site_id: cms_site.id, url: @url)
        @job = Voice::SynthesisJob.call_async @item.id.to_s
        @cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env} > /dev/null 2>&1"
      end

      before do
        http.options real_path: "/test-001.html", last_modified: nil
      end

      after :all do
        clean_database
      end

      it { expect(@job).not_to be_nil }
      it { expect(system(@cmd)).to be_truthy }

      describe "job" do
        subject { Job::Task.find_by(name: 'job:voice_synthesis') rescue nil }
        it { should be_nil }
      end

      describe "voice_file" do
        subject { Voice::File.find_by(url: @url) rescue nil }
        it { should_not be_nil }
        its(:page_identity) { expect(subject.page_identity).to_not be_nil }
        its(:lock_until) { should eq Time.zone.at(0) }
        its(:error) { should be_nil }
        its(:has_error) { should eq 0 }
        its(:age) { should be > 0 }
      end
    end
  end

  describe '#call', open_jtalk: true do
    subject(:site) { cms_site }

    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}"
      end

      before do
        http.options real_path: "/test-001.html"
      end

      after :all do
        clean_database
      end

      subject { Voice::File.find_or_create_by(site_id: site.id, url: @url) }

      it "creates voice file" do
        expect { Voice::SynthesisJob.new.call(subject.id) }.to \
          change { subject.exists? }.from(false).to(true)

        subject.reload
        expect(subject.same_identity?).to be_truthy
        expect(subject.latest?).to be_truthy
        expect(subject.error).to be_nil
        expect(subject.has_error).to eq 0
        expect(subject.age).to be > 0
      end
    end

    context 'when get 404' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @url = "http://127.0.0.1:33190/#{@path}?status_code=404"
      end

      before do
        http.options real_path: "/test-001.html", status_code: 404
      end

      after :all do
        clean_database
      end

      subject { Voice::File.find_or_create_by(site_id: site.id, url: @url) }

      it "creates dows not voice file" do
        expect { Voice::SynthesisJob.new.call(subject.id) }.to raise_error OpenURI::HTTPError
        expect(Voice::File.where(id: subject.id).count).to eq 0
      end
    end

    context 'when server timed out' do
      before :all do
        @path = "#{rand(0x100000000).to_s(36)}.html"
        @wait = SS.config.voice.download['timeout_sec'] + 5
        @url = "http://127.0.0.1:33190/#{@path}?wait=#{@wait}"
      end

      before do
        http.options real_path: "/test-001.html", wait: @wait
      end

      after :all do
        clean_database
      end

      subject { Voice::File.find_or_create_by(site_id: site.id, url: @url) }

      it "creates dows not voice file" do
        expect { Voice::SynthesisJob.new.call(subject.id) }.to raise_error Timeout::Error
        expect(Voice::File.where(id: subject.id).count).to eq 0
      end
    end
  end

  describe '#purge_pending_tasks' do
    before do
      clean_database
    end

    context "when there is no tasks" do
      it do
        expect { described_class.purge_pending_tasks }.not_to raise_error
      end
    end

    context "when there is 20 tasks and 1 is too old" do
      before do
        1.upto(20) do |id|
          Voice::SynthesisJob.call_async id.to_s
        end

        first_task = Job::Task.first
        first_task.created = 10.minutes.ago
        first_task.save!
      end

      it do
        expect { described_class.purge_pending_tasks }.to \
          change { Job::Task.count }.from(20).to(19)
      end

      it do
        expect(described_class.purge_pending_tasks).to eq 1
      end
    end
  end
end
