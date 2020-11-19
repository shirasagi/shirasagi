require 'spec_helper'

describe Gws::Survey::TrashPurgeJob, dbscope: :example do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item) { create(:gws_survey_form, cur_site: site, deleted: now - 7.days) }

  describe '#perform' do
    context 'no survey forms are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.not_to(change { Gws::Survey::Form.count })

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'survey forms are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '7') }.to \
          change { Gws::Survey::Form.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
