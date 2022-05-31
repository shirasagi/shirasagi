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

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 1
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/gws_report_files-report-#{report.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
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

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 1
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/gws_report_files-report-#{report.id}")
          body = JSON.parse(request['body'])
          expect(body['url']).to eq "/.g#{site.id}/report/files/redirect/#{report.id}"
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

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 1
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/gws_report_files-report-#{report.id}")
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

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(es_requests.length).to eq 1
        es_requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/gws_report_files-report-#{report.id}")
        end
      end
    end
  end
end
