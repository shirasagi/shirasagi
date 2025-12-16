require 'spec_helper'

describe Gws::Elasticsearch::Indexer::BoardTopicJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:file_path) { Rails.root.join('spec', 'fixtures', 'ss', 'logo.png') }
  let(:file) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }
  let(:category) { create(:gws_board_category, cur_site: site) }

  describe '.convert_to_doc' do
    let!(:topic) do
      create(
        :gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id],
        contributor_model: "Gws::User", contributor_id: user.id, contributor_name: user.name
      )
    end

    it do
      id, doc = described_class.convert_to_doc(site, topic, topic)
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      expect(id).to eq "gws_board_posts-post-#{topic.id}"
      expect(doc[:collection_name]).to eq topic.collection_name.to_sym
      expect(doc[:url]).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#post-#{topic.id}"
      expect(doc[:name]).to eq topic.name
      expect(doc[:text]).to eq topic.text
      expect(doc[:categories]).to eq [ category.name ]
      expect(doc[:user_name]).to eq user.name
      expect(doc[:mode]).to eq topic.mode
      expect(doc[:release_date]).to be_blank
      expect(doc[:close_date]).to be_blank
      expect(doc[:released]).to eq topic.released.iso8601
      expect(doc[:state]).to eq topic.state
      expect(doc[:member_ids]).to eq topic.member_ids
      expect(doc[:member_group_ids]).to eq topic.member_group_ids
      expect(doc[:member_custom_group_ids]).to eq topic.member_custom_group_ids
      expect(doc[:readable_group_ids]).to eq topic.readable_group_ids
      expect(doc[:readable_custom_group_ids]).to eq topic.readable_custom_group_ids
      expect(doc[:readable_member_ids]).to eq topic.readable_member_ids
      expect(doc[:group_ids]).to eq topic.group_ids
      expect(doc[:user_ids]).to eq topic.group_ids
      expect(doc[:custom_group_ids]).to eq topic.custom_group_ids
      expect(doc[:updated]).to eq topic.updated.iso8601
      expect(doc[:created]).to eq topic.created.iso8601

      omittable_fields = %i[id groups group_names text_index data file site_id attachment]
      unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
      expect(unhandled_keys).to be_blank
    end
  end

  describe '.convert_file_to_doc' do
    let!(:topic) do
      create(
        :gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id],
        contributor_model: "Gws::User", contributor_id: user.id, contributor_name: user.name
      )
    end

    it do
      id, doc = described_class.convert_file_to_doc(site, topic, topic, topic.files.first)
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      omittable_fields = %i[id mode text user_name groups group_names member_group_ids text_index site_id attachment]
      unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
      expect(unhandled_keys).to be_blank
    end
  end

  describe '.callback' do
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

    context 'when model was created' do
      it do
        topic = nil
        perform_enqueued_jobs do
          expectation = expect do
            topic = create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
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
            expect(es_doc["_id"]).to eq "gws_board_posts-post-#{topic.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#post-#{topic.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{file.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#file-#{file.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.text = unique_id
            topic.file_ids = []
            topic.save!
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
            expect(es_doc["_id"]).to eq "gws_board_posts-post-#{topic.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}#post-#{topic.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.destroy
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
      let!(:topic) do
        create(:gws_board_topic, cur_site: site, cur_user: user, category_ids: [category.id], file_ids: [file.id])
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            topic.deleted = Time.zone.now
            topic.save!
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
