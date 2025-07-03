require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
  let(:required) { "optional" }
  let(:input_type) { "single" }
  let(:max_length) { nil }
  let(:i18n_default_value_translations) { nil }
  let(:validation_type) { "none" }
  let(:i18n_state) { "disabled" }
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, required: required,
      input_type: input_type, max_length: max_length, validation_type: validation_type,
      i18n_state: i18n_state, i18n_default_value_translations: i18n_default_value_translations)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    form.reload
    release = form.current_release
    expect(release).to be_present
  end

  context "input_type is single" do
    let(:input_type) { "single" }

    context "with actual value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:text_value) { unique_id }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form, "col_#{column1.id}" => text_value)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq text_value

        I18n.available_locales.each do |lang|
          I18n.with_locale(lang) do
            text = file_data.read_csv_value(column1)
            expect(text).to eq text_value
          end
        end
      end
    end

    context "with nil value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to be_blank

        I18n.available_locales.each do |lang|
          I18n.with_locale(lang) do
            text = file_data.read_csv_value(column1)
            expect(text).to be_blank
          end
        end
      end
    end
  end

  context "i18n_state is enabled" do
    let(:i18n_state) { "enabled" }

    context "with actual value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:text_value_translations) { i18n_translations(prefix: "text") }
      let!(:file_data) do
        file_model.create!(
          cur_site: site, cur_user: user, cur_space: space, cur_form: form,
          "col_#{column1.id}_translations" => text_value_translations)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq text_value_translations[I18n.default_locale]

        I18n.available_locales.each do |lang|
          I18n.with_locale(lang) do
            text = file_data.read_csv_value(column1, locale: lang)
            expect(text).to eq text_value_translations[lang]
          end
        end
      end
    end

    context "with nil value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let!(:file_data) do
        file_model.create!(cur_site: site, cur_user: user, cur_space: space, cur_form: form)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to be_blank

        I18n.available_locales.each do |lang|
          I18n.with_locale(lang) do
            text = file_data.read_csv_value(column1, locale: lang)
            expect(text).to be_blank
          end
        end
      end
    end

    context "with only default locale value" do
      let(:file_model) { Gws::Tabular::File[form.current_release] }
      let(:text_value_translations) { { I18n.default_locale => "text-#{unique_id}" }.with_indifferent_access }
      let!(:file_data) do
        file_model.create!(
          cur_site: site, cur_user: user, cur_space: space, cur_form: form,
          "col_#{column1.id}_translations" => text_value_translations)
      end

      it do
        text = file_data.read_csv_value(column1)
        expect(text).to eq text_value_translations[I18n.default_locale]

        I18n.available_locales.each do |lang|
          I18n.with_locale(lang) do
            text = file_data.read_csv_value(column1, locale: lang)
            expect(text).to eq text_value_translations[I18n.default_locale]
          end
        end
      end
    end
  end
end
