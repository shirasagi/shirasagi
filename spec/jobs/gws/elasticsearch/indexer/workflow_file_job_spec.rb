require 'spec_helper'

describe Gws::Elasticsearch::Indexer::WorkflowFileJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:es_host) { "#{unique_id}.example.jp" }
  let(:es_url) { "http://#{es_host}" }
  let(:attachment) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
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
        workflow = nil
        perform_enqueued_jobs do
          expectation = expect do
            workflow = create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/workflow-#{workflow.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}"
        end
        requests.second.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/file-#{attachment.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}#file-#{attachment.id}"
        end
      end
    end

    context 'when model was updated' do
      let!(:workflow) do
        create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.text = unique_id
            workflow.file_ids = []
            workflow.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/workflow-#{workflow.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}"
        end
        # file was removed from topic
        requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{attachment.id}")
        end
      end
    end

    context 'when model was destroyed' do
      let!(:workflow) do
        create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/workflow-#{workflow.id}")
        end
        # file was removed from topic
        requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{attachment.id}")
        end
      end
    end

    context 'when model was soft deleted' do
      let!(:workflow) do
        create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            workflow.deleted = Time.zone.now
            workflow.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 2
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/workflow-#{workflow.id}")
        end
        # file was removed from topic
        requests.second.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/file-#{attachment.id}")
        end
      end
    end
  end
end
