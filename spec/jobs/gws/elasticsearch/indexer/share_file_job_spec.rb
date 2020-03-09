require 'spec_helper'

describe Gws::Elasticsearch::Indexer::ShareFileJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:es_host) { "#{unique_id}.example.jp" }
  let(:es_url) { "http://#{es_host}" }
  let(:content) { tmpfile { |file| file.write('0123456789') } }
  let(:up) { Fs::UploadedFile.create_from_file(content, basename: 'spec', content_type: 'application/octet-stream') }
  let(:requests) { [] }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = es_url
    site.save!
  end

  before do
    stub_request(:any, /#{::Regexp.escape(es_host)}/).to_return do |request|
      # examine request later
      requests << request.as_json.dup
      { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
    end
  end

  after do
    WebMock.reset!
  end

  describe '.callback' do
    context 'when model was created' do
      it do
        file = nil
        perform_enqueued_jobs do
          expectation = expect do
            file = create(:gws_share_file, cur_site: site, cur_user: user, in_file: up)
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/share/-/folder-#{file.folder_id}/files/#{file.id}"
        end
      end
    end

    context 'when model was updated' do
      let!(:file) do
        create(:gws_share_file, cur_site: site, cur_user: user, in_file: up)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            file.name = unique_id
            file.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/share/-/folder-#{file.folder_id}/files/#{file.id}"
        end
      end
    end

    context 'when model was destroyed' do
      let!(:file) do
        create(:gws_share_file, cur_site: site, cur_user: user, in_file: up)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            file.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end

    context 'when model was soft deleted' do
      let!(:file) do
        create(:gws_share_file, cur_site: site, cur_user: user, in_file: up)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            file.deleted = Time.zone.now
            file.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{file.id}")
        end
      end
    end
  end
end
