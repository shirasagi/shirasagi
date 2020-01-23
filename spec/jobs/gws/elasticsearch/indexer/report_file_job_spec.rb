require 'spec_helper'

describe Gws::Elasticsearch::Indexer::ReportFileJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { gws_user }
  let(:es_host) { "#{unique_id}.example.jp" }
  let(:es_url) { "http://#{es_host}" }
  let!(:form) { create(:gws_report_form, cur_site: site, cur_user: user, state: 'public') }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form) }
  let(:requests) { [] }

  before do
    # enable elastic search
    site.menu_elasticsearch_state = 'show'
    site.elasticsearch_hosts = es_url
    site.save!
  end

  before do
    stub_request(:any, /#{::Regexp.escape(es_host)}/).to_return do |request|
      # examine request later
      requests << request.as_json.dup
      { body: '{}', status: 200, headers: { 'Content-Type' => 'application/json; charset=UTF-8' } }
    end
  end

  after do
    WebMock.reset!
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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/report-#{report.id}")
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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'put'
          expect(request['uri']['path']).to end_with("/report-#{report.id}")
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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/report-#{report.id}")
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
          expect(log.logs).to include(include('INFO -- : Started Job'))
          expect(log.logs).to include(include('INFO -- : Completed Job'))
        end

        expect(requests.length).to eq 1
        requests.first.tap do |request|
          expect(request['method']).to eq 'delete'
          expect(request['uri']['path']).to end_with("/report-#{report.id}")
        end
      end
    end
  end
end
