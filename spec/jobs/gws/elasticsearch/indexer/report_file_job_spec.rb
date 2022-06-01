require 'spec_helper'

describe Gws::Elasticsearch::Indexer::ReportFileJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let!(:form) { create(:gws_report_form, cur_site: site, cur_user: user, state: 'public') }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form) }

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
        report = nil
        perform_enqueued_jobs do
          expectation = expect do
            report = create(:gws_report_file, cur_site: site, cur_user: user, cur_form: form)
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
            expect(es_doc["_id"]).to eq "gws_report_files-report-#{report.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:report) do
        create(:gws_report_file, cur_site: site, cur_user: user, cur_form: form)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            report.name = unique_id
            report.save!
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
            expect(es_doc["_id"]).to eq "gws_report_files-report-#{report.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:report) do
        create(:gws_report_file, cur_site: site, cur_user: user, cur_form: form)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            report.destroy
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
      let!(:report) do
        create(:gws_report_file, cur_site: site, cur_user: user, cur_form: form)
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            report.deleted = Time.zone.now
            report.save!
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
