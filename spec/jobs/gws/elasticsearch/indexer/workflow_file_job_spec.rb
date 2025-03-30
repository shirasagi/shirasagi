require 'spec_helper'

describe Gws::Elasticsearch::Indexer::WorkflowFileJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:attachment) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.save!

    # gws:es:ingest:init
    Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    Gws::Elasticsearch.create_index(site: site)
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

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_workflow_files-workflow-#{workflow.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{attachment.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}#file-#{attachment.id}"
          end
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

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          # confirm that file was removed from topic
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_workflow_files-workflow-#{workflow.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/workflow/files/all/#{workflow.id}"
          end
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

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
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

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 0
        end
      end
    end
  end
end
