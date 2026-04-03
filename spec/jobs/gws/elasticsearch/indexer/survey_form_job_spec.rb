require 'spec_helper'

describe Gws::Elasticsearch::Indexer::SurveyFormJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }

  describe '#convert_to_doc' do
    let!(:cate) { create :gws_survey_category, cur_site: site }
    let!(:contributor) { create :gws_user, group_ids: user.group_ids }
    let!(:form) do
      create(
        :gws_survey_form, cur_site: site, cur_user: user, category_ids: [ cate.id ],
        contributor_model: contributor.class.name, contributor_id: contributor.id,
        contributor_name: contributor.name
      )
    end
    let(:choice) { "choice-#{unique_id}" }
    let!(:column) do
      create(
        :gws_column_select, cur_site: site, form: form, required: "optional", select_options: [ choice ]
      )
    end

    it do
      job = described_class.new
      job.site_id = site.id
      job.user_id = user.id
      job.instance_variable_set(:@id, form.id.to_s)
      id, doc = job.send(:convert_to_doc)
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      expect(id).to eq "gws_survey_forms-survey-#{form.id}"
      expect(doc[:collection_name]).to eq form.collection_name
      expect(doc[:url]).to eq "/.g#{site.id}/survey/-/-/editables/#{form.id}"

      # 英語テキストは英語用フィールドへ、日本語テキストは日本語フィールドへ。
      # そうすることで、無駄なインデクシングを減らし、Elasticsearch のインデクシングサイズを最適に保ち、かつ、
      # 検索時のトークンの照合回数を減らすことで検索性能の向上・維持に務める。
      expect(doc[:name]).to eq form.name
      expect(doc[:text]).to include form.description
      expect(doc[:text]).to include(include(column.name))
      expect(doc[:text]).to include(include(choice))
      expect(doc[:categories]).to eq [ cate.name ]
      expect(doc[:user_name]).to eq user.long_name

      expect(doc[:state]).to eq form.state
      expect(doc[:readable_group_ids]).to eq form.readable_group_ids
      expect(doc[:readable_custom_group_ids]).to eq form.readable_custom_group_ids
      expect(doc[:readable_member_ids]).to eq form.readable_member_ids
      expect(doc[:group_ids]).to eq form.group_ids
      expect(doc[:user_ids]).to eq form.group_ids
      expect(doc[:custom_group_ids]).to eq form.custom_group_ids
      expect(doc[:updated]).to eq form.updated.iso8601
      expect(doc[:created]).to eq form.created.iso8601

      omittable_fields = %i[
        id mode groups group_names released member_ids member_group_ids member_custom_group_ids
        text_index data file site_id attachment
      ]
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
        form = nil
        perform_enqueued_jobs do
          expectation = expect do
            form = create(:gws_survey_form, cur_site: site, cur_user: user)
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
            expect(es_doc["_id"]).to eq "gws_survey_forms-survey-#{form.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/survey/-/-/editables/#{form.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:form) do
        create(:gws_survey_form, cur_site: site, cur_user: user)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            form.description = unique_id
            form.save!
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
            expect(es_doc["_id"]).to eq "gws_survey_forms-survey-#{form.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/survey/-/-/editables/#{form.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:form) do
        create(:gws_survey_form, cur_site: site, cur_user: user)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            form.destroy
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
      let!(:form) do
        create(:gws_survey_form, cur_site: site, cur_user: user)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            form.deleted = Time.zone.now
            form.save!
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

    context 'when column was changed' do
      it do
        form = nil
        perform_enqueued_jobs do
          expectation = expect do
            form = create(:gws_survey_form, cur_site: site, cur_user: user)
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
            expect(es_doc["_id"]).to eq "gws_survey_forms-survey-#{form.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/survey/-/-/editables/#{form.id}"
          end
        end

        # column created
        column = nil
        perform_enqueued_jobs do
          expectation = expect do
            column = create(:gws_column_text_field, cur_site: site, form: form, required: "optional", input_type: "text")
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all[1].tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # column changed
        perform_enqueued_jobs do
          expectation = expect do
            column.name = unique_id
            column.save!
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 3
        Gws::Job::Log.all[2].tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # column destroyed
        perform_enqueued_jobs do
          expectation = expect do
            column.destroy
          end
          expectation.to change { performed_jobs.size }.by(1)
        end

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 4
        Gws::Job::Log.all[3].tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
