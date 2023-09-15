require 'spec_helper'

describe Gws::Elasticsearch::Indexer::SurveyFormJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }

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
        form = nil
        perform_enqueued_jobs do
          expectation = expect do
            form = create(:gws_survey_form, cur_site: site, cur_user: user)
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
        ::Gws::Elasticsearch.refresh_index(site: site)

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
        ::Gws::Elasticsearch.refresh_index(site: site)

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
        ::Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 4
        Gws::Job::Log.all[3].tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
