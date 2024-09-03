require 'spec_helper'

describe Gws::Workflow2::TrashPurgeJob, dbscope: :example do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:form) { create(:gws_workflow2_form_application, state: "public", agent_state: "enabled") }
  let!(:column1) do
    create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text", required: "optional")
  end
  let(:column1_value) { unique_id }

  let!(:item1) do
    create(
      :gws_workflow2_file, cur_site: site, cur_form: form, column_values: [ column1.serialize_value(column1_value) ],
      deleted: now - 7.days
    )
  end
  let!(:item2) do
    create(
      :gws_workflow2_file, cur_site: site, cur_form: form, column_values: [ column1.serialize_value(column1_value) ],
      deleted: now - 2.years
    )
  end

  describe '#perform' do
    context '1 workflow files are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { Gws::Workflow2::File.count }.by(-1)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context '2 workflow files are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '7.days') }.to \
          change { Gws::Workflow2::File.count }.by(-2)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'no workflow files are purged' do
      it do
        expect { described_class.bind(site_id: site).perform_now(threshold: '3.years') }.to \
          change { Gws::Workflow2::File.count }.by(0)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when group trash_threshold is 7.days' do
      before do
        site.set(trash_threshold: 7)
        site.set(trash_threshold_unit: 'day')
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { Gws::Workflow2::File.count }.by(-2)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context 'when group trash_threshold is 3.years' do
      before do
        site.set(trash_threshold: 3)
        site.set(trash_threshold_unit: 'years')
      end

      it do
        expect { described_class.bind(site_id: site).perform_now }.to change { Gws::Workflow2::File.count }.by(0)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
