require 'spec_helper'

describe Voice::SynthesisJob, dbscope: :example do
  let(:site) { cms_site }

  before { WebMock.reset! }
  after { WebMock.reset! }

  describe '#perform', open_jtalk: true do
    context 'when synthesize from file "fixtures/voice/test-001.html"' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        path = Rails.root.join("spec", "fixtures", "voice", "test-001.html")
        body = ::File.read(path)
        last_modified = ::File.mtime(path).httpdate
        stub_request(:get, url).to_return(status: 200, body: body, headers: { 'Last-Modified' => last_modified })
      end

      it "generates voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        file.reload
        expect(file.exists?).to be_truthy
        expect(file.same_identity?).to be_truthy
        expect(file.latest?).to be_truthy
        expect(file.lock_until).to eq ::Time::EPOCH
        expect(file.error).to be_nil
        expect(file.has_error).to eq 0
        expect(file.age).to be > 0

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when get 400' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        stub_request(:get, url).to_return(status: [400, 'Bad Request'])
      end

      it "does not generate voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/ INFO -- : .* Started Job/)
          expect(log.logs).to include(/ INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/ WARN -- : .* OpenURI::HTTPError \(400 Bad Request\):/)
          expect(log.logs).to include(/FATAL -- : .* Failed Job/)
        end
      end
    end

    context 'when get 404' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        stub_request(:get, url).to_return(status: [404, 'Not Found'])
      end

      it "does not generate voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/ INFO -- : .* Started Job/)
          expect(log.logs).to include(/ INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/ WARN -- : .* OpenURI::HTTPError \(404 Not Found\):/)
          expect(log.logs).to include(/FATAL -- : .* Failed Job/)
        end
      end
    end

    context 'when get 500' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        stub_request(:get, url).to_return(status: [500, 'Internal Server Error'])
      end

      it "does not generate voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/ INFO -- : .* Started Job/)
          expect(log.logs).to include(/ INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/ WARN -- : .* OpenURI::HTTPError \(500 Internal Server Error\):/)
          expect(log.logs).to include(/FATAL -- : .* Failed Job/)
        end
      end
    end

    context 'when server timed out' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }
      let(:wait) { SS.config.voice.download['timeout_sec'] + 5 }

      before do
        stub_request(:get, url).to_timeout
      end

      it "does not generate voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/ INFO -- : .* Started Job/)
          expect(log.logs).to include(/ INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/ WARN -- : .* Net::OpenTimeout \(execution expired\):/)
          expect(log.logs).to include(/FATAL -- : .* Failed Job/)
        end
      end
    end

    context 'when server does not respond last_modified' do
      let(:path) { "#{unique_id}.html" }
      let(:url) { "http://127.0.0.1:33190/#{path}" }
      let(:file) { Voice::File.find_or_create_by(site_id: site.id, url: url) }

      before do
        # http.options real_path: "/test-001.html", last_modified: nil
        body = ::File.read(Rails.root.join("spec", "fixtures", "voice", "test-001.html"))
        stub_request(:get, url).to_return(status: 200, body: body)
      end

      it "generates voice file" do
        Voice::SynthesisJob.bind(site_id: site).perform_now(file.id.to_s)

        file.reload
        expect(file.page_identity).not_to be_nil
        expect(file.lock_until).to eq ::Time::EPOCH
        expect(file.error).to be_nil
        expect(file.has_error).to eq 0
        expect(file.age).to be > 0

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* synthesize: #{::Regexp.escape(url)}/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
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
