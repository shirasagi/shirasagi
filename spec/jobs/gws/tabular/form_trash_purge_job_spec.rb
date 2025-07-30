require 'spec_helper'

describe Gws::Tabular::FormTrashPurgeJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:space) { create(:gws_tabular_space, cur_site: site, cur_user: admin) }
  let!(:form1) { create(:gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space, state: 'publishing') }
  let!(:column1_1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form1, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled", required: "optional")
  end
  let!(:column1_2) do
    create(:gws_tabular_column_file_upload_field, cur_site: site, cur_form: form1, order: 20, required: "optional")
  end
  let!(:form2) { create(:gws_tabular_form, cur_site: site, cur_user: admin, cur_space: space, state: 'publishing') }
  let!(:column2_1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form2, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled", required: "optional")
  end
  let!(:column2_2) do
    create(:gws_tabular_column_file_upload_field, cur_site: site, cur_form: form2, order: 20, required: "optional")
  end

  let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:attachment1) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo1.png') }
  let!(:attachment2) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo2.png') }

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form1.id.to_s)
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form2.id.to_s)

    form1.reload
    form1_model = Gws::Tabular::File[form1.current_release]
    form1_file = form1_model.new(cur_site: site, cur_space: space, cur_form: form1)
    form1_file.send("col_#{column1_1.id}=", unique_id)
    form1_file.send("col_#{column1_2.id}=", attachment1)
    form1_file.save!

    form2.reload
    form2_model = Gws::Tabular::File[form2.current_release]
    form2_file = form2_model.new(cur_site: site, cur_space: space, cur_form: form2)
    form2_file.send("col_#{column2_1.id}=", unique_id)
    form2_file.send("col_#{column2_2.id}=", attachment2)
    form2_file.save!

    form1.update!(state: "closed", deleted: now - 7.days)
    form2.update!(state: "closed", deleted: now - 2.years)
  end

  describe '#perform' do
    let(:form1_model) { Gws::Tabular::File[form1.current_release] }
    let(:form2_model) { Gws::Tabular::File[form2.current_release] }

    before do
      expect(form1_model.all.count).to be > 0
      expect(form2_model.all.count).to be > 0
    end

    context '1 form is purged' do
      it do
        expect { described_class.bind(site_id: site.id).perform_now }.to change { Gws::Tabular::Form.all.count }.by(-1)

        expect(Job::Log.all.count).to be > 0
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Tabular::FormRelease.where(form_id: form1.id).all.count).to be > 0
        expect(Gws::Tabular::FormRelease.where(form_id: form2.id).all.count).to eq 0
        expect(form1_model.all.count).to be > 0
        expect(form2_model.all.count).to eq 0
        expect { attachment1.reload }.not_to raise_error
        expect { attachment2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    context '2 forms are purged' do
      it do
        expect { described_class.bind(site_id: site.id).perform_now(threshold: '7.days') }.to \
          change { Gws::Tabular::Form.all.count }.by(-2)

        expect(Job::Log.all.count).to be > 0
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Tabular::FormRelease.where(form_id: form1.id).all.count).to eq 0
        expect(Gws::Tabular::FormRelease.where(form_id: form2.id).all.count).to eq 0
        expect(form1_model.all.count).to eq 0
        expect(form2_model.all.count).to eq 0
        expect { attachment1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { attachment2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    context 'no forms are purged' do
      it do
        expect { described_class.bind(site_id: site.id).perform_now(threshold: '3.years') }.to \
          change { Gws::Tabular::Form.all.count }.by(0)

        expect(Job::Log.all.count).to be > 0
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Tabular::FormRelease.where(form_id: form1.id).all.count).to be > 0
        expect(Gws::Tabular::FormRelease.where(form_id: form2.id).all.count).to be > 0
        expect(form1_model.all.count).to be > 0
        expect(form2_model.all.count).to be > 0
        expect { attachment1.reload }.not_to raise_error
        expect { attachment2.reload }.not_to raise_error
      end
    end

    context 'group trash_threshold is 7.days => 2 forms are purged' do
      before do
        site.set(trash_threshold: 7)
        site.set(trash_threshold_unit: 'day')
      end

      it do
        expect { described_class.bind(site_id: site.id).perform_now }.to \
          change { Gws::Tabular::Form.all.count }.by(-2)

        expect(Job::Log.all.count).to be > 0
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Tabular::FormRelease.where(form_id: form1.id).all.count).to eq 0
        expect(Gws::Tabular::FormRelease.where(form_id: form2.id).all.count).to eq 0
        expect(form1_model.all.count).to eq 0
        expect(form2_model.all.count).to eq 0
        expect { attachment1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { attachment2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    context 'group trash_threshold is 3.years => no forms are purged' do
      before do
        site.set(trash_threshold: 3)
        site.set(trash_threshold_unit: 'years')
      end

      it do
        expect { described_class.bind(site_id: site.id).perform_now }.to change { Gws::Tabular::Form.all.count }.by(0)

        expect(Job::Log.all.count).to be > 0
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Tabular::FormRelease.where(form_id: form1.id).all.count).to be > 0
        expect(Gws::Tabular::FormRelease.where(form_id: form2.id).all.count).to be > 0
        expect(form1_model.all.count).to be > 0
        expect(form2_model.all.count).to be > 0
        expect { attachment1.reload }.not_to raise_error
        expect { attachment2.reload }.not_to raise_error
      end
    end
  end
end
