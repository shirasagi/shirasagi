require 'spec_helper'

describe Gws::Tabular::FormPublishJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe '#perform' do
    let!(:space) { create :gws_tabular_space, cur_site: site }
    let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
    let!(:column1) do
      create(:gws_tabular_column_text_field, cur_site: site, cur_form: form, input_type: "single", required: "optional")
    end

    context "initial release" do
      it do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Gws::Tabular::Form.find(form.id).tap do |after_form|
          expect(after_form.state).to eq 'public'
        end

        expect(form.releases.count).to eq 1
        form.current_release.tap do |current_release|
          expect(current_release.form_id).to eq form.id
          expect(current_release.revision).to eq form.revision
          expect(current_release.patch).to eq 0
          expect(::File.size(current_release.archive_path)).to be > 0
          expect(::File.size(current_release.migration_rb_path)).to be > 0
        end
      end
    end

    context "2nd release" do
      it do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        form.reload
        form.update(state: 'publishing', revision: form.revision + 1)

        create(:gws_tabular_column_text_field, cur_site: site, cur_form: form, input_type: "single", required: "optional")
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        Gws::Tabular::Form.find(form.id).tap do |after_form|
          expect(after_form.state).to eq 'public'
        end

        expect(form.releases.count).to eq 2
        form.current_release.tap do |current_release|
          expect(current_release.form_id).to eq form.id
          expect(current_release.revision).to eq form.revision
          expect(current_release.patch).to eq 0
          expect(::File.size(current_release.archive_path)).to be > 0
          expect(::File.size(current_release.migration_rb_path)).to be > 0
        end
      end
    end
  end
end
