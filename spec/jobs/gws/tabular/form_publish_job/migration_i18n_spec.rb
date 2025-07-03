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
        max_length: nil, validation_type: "none", i18n_state: i18n_state_1st, index_state: "none")
    end
    let!(:column1_value) { unique_id }
    let!(:column1_value_translations) { i18n_translations(prefix: "col") }

    before do
      described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      file_model = Gws::Tabular::File[form.current_release]
      if i18n_state_1st == "enabled"
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}_translations" => column1_value_translations)
      else
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => column1_value)
      end

      form.reload
      form.update(state: 'publishing', revision: form.revision + 1)

      column1.update(i18n_state: i18n_state_2nd)

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

    context "i18n: off -> on" do
      let(:i18n_state_1st) { "disabled" }
      let(:i18n_state_2nd) { "enabled" }

      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.unscoped.count).to eq 1
        file_model.unscoped.first.tap do |item|
          item.send("col_#{column1.id}_translations").tap do |translations|
            expect(translations[I18n.default_locale]).to eq column1_value
            I18n.available_locales.each do |lang|
              next if lang == I18n.default_locale
              expect(translations[lang]).to be_blank
            end
          end
        end
      end
    end

    context "i18n: on -> off" do
      let(:i18n_state_1st) { "enabled" }
      let(:i18n_state_2nd) { "disabled" }

      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.unscoped.count).to eq 1
        file_model.unscoped.first.tap do |item|
          expect(item.send("col_#{column1.id}")).to eq column1_value_translations[I18n.default_locale]
        end
      end
    end
  end
end
