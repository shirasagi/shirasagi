require 'spec_helper'

describe Gws::Tabular::FormPublishJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe '#perform' do
    let!(:space) { create :gws_tabular_space, cur_site: site }
    let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }

    context "integer -> text" do
      let!(:column1) do
        create(
          :gws_tabular_column_number_field, cur_site: site, cur_form: form, required: "optional",
          field_type: "integer", min_value: nil, max_value: nil)
      end
      let(:column1_value) { rand(10..20) }

      before do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        file_model = Gws::Tabular::File[form.current_release]
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => column1_value)

        form.reload
        form.update(state: 'publishing', revision: form.revision + 1)

        column1.set(_type: Gws::Tabular::Column::TextField.name)
        Gws::Column::Base.find(column1.id).tap do |column1_renew|
          column1_renew.update!(input_type: "single", max_length: nil, validation_type: "none", i18n_state: "disabled")
        end

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

      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.unscoped.count).to eq 1
        file_model.unscoped.first.tap do |item|
          expect(item.send("col_#{column1.id}")).to eq column1_value.to_s
        end
      end
    end

    context "integer -> i18n" do
      let!(:column1) do
        create(
          :gws_tabular_column_number_field, cur_site: site, cur_form: form, required: "optional",
          field_type: "integer", min_value: nil)
      end
      let(:column1_value) { rand(10..20) }

      before do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        file_model = Gws::Tabular::File[form.current_release]
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => column1_value)

        form.reload
        form.update(state: 'publishing', revision: form.revision + 1)

        column1.set(_type: Gws::Tabular::Column::TextField.name)
        Gws::Column::Base.find(column1.id).tap do |column1_renew|
          column1_renew.update!(input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled")
        end

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

      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.unscoped.count).to eq 1
        file_model.unscoped.first.tap do |item|
          item.send("col_#{column1.id}_translations").tap do |translations|
            expect(translations[I18n.default_locale]).to eq column1_value.to_s
            I18n.available_locales.each do |lang|
              next if lang == I18n.default_locale
              expect(translations[lang]).to be_blank
            end
          end
        end
      end
    end

    context "text -> integer" do
      let!(:column1) do
        create(
          :gws_tabular_column_text_field, cur_site: site, cur_form: form, required: "optional",
          input_type: "single", max_length: nil, validation_type: "none", i18n_state: "disabled")
      end

      before do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        file_model = Gws::Tabular::File[form.current_release]
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}" => column1_value)

        form.reload
        form.update(state: 'publishing', revision: form.revision + 1)

        column1.set(_type: Gws::Tabular::Column::NumberField.name)
        Gws::Column::Base.find(column1.id).tap do |column1_renew|
          column1_renew.update!(field_type: "integer", min_value: nil, default_value: rand(20..30))
        end

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

      context "with valid integer" do
        let(:column1_value) { rand(10..20).to_s }

        it do
          file_model = Gws::Tabular::File[form.current_release]
          expect(file_model.unscoped.count).to eq 1
          file_model.unscoped.first.tap do |item|
            expect(item.send("col_#{column1.id}")).to eq column1_value.to_i
          end
        end
      end

      context "with invalid integer" do
        let(:column1_value) { "text-#{unique_id}" }

        it do
          column1_renew = Gws::Column::Base.find(column1.id)
          file_model = Gws::Tabular::File[form.current_release]
          expect(file_model.unscoped.count).to eq 1
          file_model.unscoped.first.tap do |item|
            expect(item.send("col_#{column1.id}")).to eq column1_renew.default_value.to_i
            expect(item.migration_errors).to have_at_least(1).items
            expect(item.migration_errors).to include(/unable to convert ".*" to integer/)
          end
        end
      end
    end

    context "i18n -> integer" do
      let!(:column1) do
        create(
          :gws_tabular_column_text_field, cur_site: site, cur_form: form, required: "optional",
          input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled")
      end

      before do
        described_class.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

        file_model = Gws::Tabular::File[form.current_release]
        file_model.create!(
          cur_site: site, cur_space: space, cur_form: form, "col_#{column1.id}_translations" => column1_value)

        form.reload
        form.update(state: 'publishing', revision: form.revision + 1)

        column1.set(_type: Gws::Tabular::Column::NumberField.name)
        Gws::Column::Base.find(column1.id).tap do |column1_renew|
          column1_renew.update!(field_type: "integer", min_value: nil, default_value: rand(20..30))
        end

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

      context "with valid integer" do
        let(:column1_value) do
          value = {}
          I18n.available_locales.each do |lang|
            value[lang] = rand(10..20).to_s
          end
          value
        end

        it do
          file_model = Gws::Tabular::File[form.current_release]
          expect(file_model.unscoped.count).to eq 1
          file_model.unscoped.first.tap do |item|
            expect(item.send("col_#{column1.id}")).to eq column1_value[I18n.default_locale].to_i
          end
        end
      end

      context "with invalid integer" do
        let(:column1_value) do
          value = {}
          I18n.available_locales.each do |lang|
            value[lang] = "text-#{unique_id}"
          end
          value
        end

        it do
          column1_renew = Gws::Column::Base.find(column1.id)
          file_model = Gws::Tabular::File[form.current_release]
          expect(file_model.unscoped.count).to eq 1
          file_model.unscoped.first.tap do |item|
            expect(item.send("col_#{column1.id}")).to eq column1_renew.default_value.to_i
            expect(item.migration_errors).to have_at_least(1).items
            expect(item.migration_errors).to include(/unable to convert ".*" to integer/)
          end
        end
      end
    end
  end
end
