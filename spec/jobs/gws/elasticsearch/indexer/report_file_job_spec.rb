require 'spec_helper'

describe Gws::Elasticsearch::Indexer::ReportFileJob, dbscope: :example, es: true do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let!(:form) { create(:gws_report_form, cur_site: site, cur_user: user, state: 'public') }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form) }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, required: "optional") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:attachment) { tmp_ss_file(user: user, contents: File.binread(file_path), binary: true, content_type: 'image/png') }

  describe '#convert_to_doc' do
    let!(:report) do
      create(
        :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
        column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
      )
    end

    it do
      job = described_class.new
      job.site_id = site.id
      job.user_id = user.id
      job.instance_variable_set(:@id, report.id.to_s)
      id, doc = job.send(:convert_to_doc)
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      omittable_fields = %i[
        id groups group_names member_group_ids text_index data
        file site_id attachment
      ]
      unhandled_keys.reject! { |key| omittable_fields.include?(key.to_sym) }
      expect(unhandled_keys).to be_blank
    end
  end

  describe '#convert_file_to_doc' do
    let!(:report) do
      create(
        :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
        column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
      )
    end

    it do
      job = described_class.new
      job.site_id = site.id
      job.user_id = user.id
      job.instance_variable_set(:@id, report.id.to_s)
      id, doc = job.send(:convert_file_to_doc, SS::File.find(attachment.id))
      unhandled_keys = [] if Rails.env.test?
      Gws::Elasticsearch.mappings_keys.each do |key|
        unless doc.key?(key.to_sym)
          unhandled_keys << key
        end
      end

      omittable_fields = %i[
        id mode text categories user_name groups group_names member_group_ids text_index
        site_id attachment
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
        report = nil
        perform_enqueued_jobs do
          expectation = expect do
            report = create(
              :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
              column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
            )
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
            expect(es_doc["_id"]).to eq "gws_report_files-report-#{report.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{attachment.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}#file-#{attachment.id}"
          end
        end
      end
    end

    context 'when model was updated' do
      let!(:report) do
        create(
          :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
        )
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
        Gws::Elasticsearch.refresh_index(site: site)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
          expect(es_docs["hits"]["hits"].length).to eq 2
          es_docs["hits"]["hits"][0].tap do |es_doc|
            expect(es_doc["_id"]).to eq "gws_report_files-report-#{report.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
          end
          es_docs["hits"]["hits"][1].tap do |es_doc|
            expect(es_doc["_id"]).to eq "file-#{attachment.id}"
            source = es_doc["_source"]
            expect(source['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}#file-#{attachment.id}"
          end
        end
      end
    end

    context 'when model was destroyed' do
      let!(:report) do
        create(
          :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
        )
      end

      it do
        perform_enqueued_jobs do
          expectation = expect do
            report.destroy
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
      let!(:report) do
        create(
          :gws_report_file, cur_site: site, cur_user: user, cur_form: form,
          column_values: [ column1.serialize_value(unique_id), column2.serialize_value([ attachment.id ]) ]
        )
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
