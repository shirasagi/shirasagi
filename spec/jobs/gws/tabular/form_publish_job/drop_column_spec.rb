require 'spec_helper'

describe Gws::Tabular::FormPublishJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe '#perform' do
    let!(:space) { create :gws_tabular_space, cur_site: site }
    let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
    let!(:column1) do
      create(
        :gws_tabular_column_text_field, cur_site: site, cur_form: form, input_type: "single", required: "optional",
        max_length: nil, validation_type: "none", i18n_state: "disabled", index_state: "none")
    end
    let!(:column2) do
      create(
        :gws_tabular_column_text_field, cur_site: site, cur_form: form, input_type: "single", required: "optional",
        max_length: nil, validation_type: "none", i18n_state: "disabled", index_state: "none")
    end

    before do
      described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      file_model = Gws::Tabular::File[form.current_release]
      file_model.create!(
        cur_site: site, cur_space: space, cur_form: form,
        "col_#{column1.id}" => unique_id, "col_#{column2.id}" => unique_id)

      form.reload
      form.update(state: 'publishing', revision: form.revision + 1)

      column2.destroy

      described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      form.reload
      expect(form.state).to eq 'public'
      expect(form.revision).to eq 2
      expect(form.releases.count).to eq 2
    end

    context "after column is dropped" do
      it do
        file_model = Gws::Tabular::File[form.current_release]
        coll = file_model.collection
        docs = coll.find({})
        expect(docs.count).to eq 1
        docs.each do |doc|
          expect(doc.keys).to include("_id", "col_#{column1.id}")
          expect(doc.keys).not_to include("col_#{column2.id}")
        end
      end
    end
  end
end
