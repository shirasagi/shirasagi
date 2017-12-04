require 'spec_helper'

describe Gws::Elasticsearch::Indexer::WorkflowFileJob, dbscope: :example, tmpdir: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:es_host) { "#{unique_id}.example.jp" }
  let(:es_url) { "http://#{es_host}" }
  let(:attachment) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = es_url
    site.save!
  end

  before do
    stub_request(:any, /#{Regexp.escape(es_host)}/).
      to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' })
  end

  after do
    WebMock.reset!
  end

  context 'indexing' do
    let!(:file) do
      create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
    end

    describe '#index' do
      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'index', id: file.id.to_s)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end
      end
    end

    describe '#delete' do
      it do
        job = described_class.bind(site_id: site)
        job.perform_now(action: 'delete', id: file.id.to_s, remove_file_ids: file.file_ids)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end
      end
    end
  end

  describe '.callback' do
    context 'when model was created' do
      it do
        expectation = expect do
          create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end

    context 'when model was updated' do
      let!(:file) do
        create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
      end

      it do
        expectation = expect do
          file.text = unique_id
          file.file_ids = []
          file.save!
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end

    context 'when model was destroyed' do
      let!(:file) do
        create(:gws_workflow_file, cur_site: site, cur_user: user, file_ids: [attachment.id])
      end

      it do
        expectation = expect do
          file.destroy
        end
        expectation.to change { enqueued_jobs.size }.by(1)
      end
    end
  end
end
