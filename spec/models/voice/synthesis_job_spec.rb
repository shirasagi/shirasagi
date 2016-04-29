require 'spec_helper'

describe Voice::SynthesisJob, dbscope: :example, http_server: true do
  http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "voice")

  let(:site) { cms_site }

  describe '#perform', open_jtalk: true do
    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        http.options real_path: "/test-001.html"
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "generates voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        file.reload
        expect(file.exists?).to be_truthy
        expect(file.same_identity?).to be_truthy
        expect(file.latest?).to be_truthy
        expect(file.lock_until).to eq ::Time::EPOCH
        expect(file.error).to be_nil
        expect(file.has_error).to eq 0
        expect(file.age).to be > 0

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end
    end

    context 'when get 400' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        http.options real_path: "/test-001.html", status_code: 400
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "does not generate voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("WARN -- : OpenURI::HTTPError (400 Bad Request ):"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
      end
    end

    context 'when get 404' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        http.options real_path: "/test-001.html", status_code: 404
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "does not generate voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("WARN -- : OpenURI::HTTPError (404 Not Found ):"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
      end
    end

    context 'when get 500' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        http.options real_path: "/test-001.html", status_code: 500
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "does not generate voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("WARN -- : OpenURI::HTTPError (500 Internal Server Error ):"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
      end
    end

    context 'when server timed out' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }
      let(:wait) { SS.config.voice.download['timeout_sec'] + 5 }

      before do
        http.options real_path: "/test-001.html", wait: wait
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "does not generate voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("WARN -- : Net::ReadTimeout (Net::ReadTimeout):"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
      end
    end

    context 'when server does not respond last_modified' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        http.options real_path: "/test-001.html", last_modified: nil
        perform_enqueued_jobs { Voice::SynthesisJob.bind(site_id: site).perform_later file.id.to_s }
      end

      it "generates voice file" do
        expect(enqueued_jobs.count).to eq 0
        expect(performed_jobs.count).to eq 1

        file.reload
        expect(file.page_identity).not_to be_nil
        expect(file.lock_until).to eq ::Time::EPOCH
        expect(file.error).to be_nil
        expect(file.has_error).to eq 0
        expect(file.age).to be > 0

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : synthesize: #{url}"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end
    end
  end

  describe '#purge_pending_tasks' do
    context "when there is no tasks" do
      it do
        expect { described_class.purge_pending_tasks }.not_to raise_error
      end
    end

    context "when there is 20 tasks and 1 is too old" do
      before do
        1.upto(20) do |id|
          Job::Task.create!(
            site_id: site.id,
            name: id.to_s,
            state: 'stop',
            pool: 'voice_synthesis',
            class_name: described_class.name,
            args: [ id.to_s ])
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
