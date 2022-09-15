require 'spec_helper'

describe Gws::Elasticsearch::Indexer::NoticePostJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:folder1) { create(:gws_notice_folder, cur_site: site) }
  let(:file1) { tmp_ss_file(contents: unique_id * rand(1..10), user: user) }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.save!

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)
  end

  describe '.callback' do
    context 'when model was created' do
      it do
        post = nil
        perform_enqueued_jobs do
          expectation = expect do
            post = create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, file_ids: [ file1.id ])
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_notices-post-#{post.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/notice/-/-/redirects/#{post.id}#post-#{post.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file1.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/notice/-/-/redirects/#{post.id}#file-#{file1.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:post) do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, file_ids: [ file1.id ])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.text = unique_id
            post.file_ids = []
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          # confirm that file was removed from topic
          expect(es_docs["hits"]["hits"].length).to eq 1
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_notices-post-#{post.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/notice/-/-/redirects/#{post.id}#post-#{post.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:post) do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, file_ids: [ file1.id ])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

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
      let!(:post) do
        create(:gws_notice_post, cur_site: site, cur_user: user, folder: folder1, file_ids: [ file1.id ])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            post.deleted = Time.zone.now
            post.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        ::Gws::Elasticsearch.refresh_index(site: site)

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
