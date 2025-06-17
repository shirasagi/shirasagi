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
        max_length: nil, validation_type: "none", i18n_state: "disabled", index_state: index_state_1st)
    end

    before do
      described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      file_model = Gws::Tabular::File[form.current_release]
      file_model.create!(cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => unique_id)

      form.reload
      form.update(state: 'publishing', revision: form.revision + 1)

      column1.update(index_state: index_state_2nd)

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

    context "index: off -> on" do
      let(:index_state_1st) { "none" }
      let(:index_state_2nd) { "asc" }

      it do
        file_model = Gws::Tabular::File[form.current_release]
        coll = file_model.collection
        coll.indexes.to_a.tap do |indexes|
          expect(indexes.length).to be >= 2
          index_names = indexes.map { |index| index["name"] }
          expect(index_names).to include("_id_", "col_#{column1.id}_1")
        end
      end
    end

    context "index: on -> off" do
      let(:index_state_1st) { "asc" }
      let(:index_state_2nd) { "none" }

      it do
        file_model = Gws::Tabular::File[form.current_release]
        coll = file_model.collection
        coll.indexes.to_a.tap do |indexes|
          expect(indexes.length).to be >= 1
          index_names = indexes.map { |index| index["name"] }
          expect(index_names).to include("_id_")
          expect(index_names).not_to include("col_#{column1.id}_1")
        end
      end
    end
  end
end
