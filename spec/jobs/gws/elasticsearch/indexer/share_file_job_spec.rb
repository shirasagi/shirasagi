require 'spec_helper'

describe Gws::Elasticsearch::Indexer::ShareFileJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:content) { tmpfile { |file| file.write('0123456789') } }
  let(:up) { Fs::UploadedFile.create_from_file(content, basename: 'spec', content_type: 'application/octet-stream') }

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
        file = nil
        perform_enqueued_jobs do
          expectation = expect do
            file = create(:gws_share_file, cur_site: site, cur_user: user, in_file: up)
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
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/share/-/folder-#{file.folder_id}/files/#{file.id}"
          end
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

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/share/-/folder-#{file.folder_id}/files/#{file.id}"
          end
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
