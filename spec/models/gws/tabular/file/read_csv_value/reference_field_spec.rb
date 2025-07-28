require 'spec_helper'

describe Gws::Tabular::File, type: :model, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:category_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let(:category_name_unique_state) { "disabled" }
  let!(:category_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: category_form, order: 10,
      input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled",
      unique_state: category_name_unique_state)
  end
  let!(:category_workflow_state_column) do
    create(:gws_tabular_column_enum_field, cur_site: site, cur_form: category_form, order: 20)
  end
  let(:workflow_state) { "disabled" }
  let!(:recycle_item_form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1,
      workflow_state: workflow_state)
  end
  let!(:recycle_item_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: recycle_item_form, order: 10, required: 'optional',
      input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled")
  end
  let!(:recycle_item_category_column) do
    create(
      :gws_tabular_column_reference_field, cur_site: site, cur_form: recycle_item_form, order: 20, required: 'optional',
      reference_form: category_form, reference_type: reference_type
    )
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(category_form.id.to_s)
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(recycle_item_form.id.to_s)

    expect(Gws::Job::Log.count).to eq 2
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    category_form.reload
    category_form_release = category_form.current_release
    expect(category_form_release).to be_present

    recycle_item_form.reload
    recycle_item_form_release = recycle_item_form.current_release
    expect(recycle_item_form_release).to be_present
  end

  context "with gws/tabular/column/reference_field" do
    describe "#read_csv_value" do
      let!(:category_model) { Gws::Tabular::File[category_form.current_release] }
      let!(:category1_name_translations) { i18n_translations(prefix: "class") }
      let!(:category1) do
        category_file = category_model.new(cur_site: site, cur_space: space, cur_form: category_form)
        category_file.send("col_#{category_name_column.id}_translations=", category1_name_translations)
        category_file.send("col_#{category_workflow_state_column.id}=", [ category_workflow_state_column.select_options.sample ])
        category_file.save!
        category_model.find(category_file.id)
      end
      let!(:category2_name_translations) { i18n_translations(prefix: "class") }
      let!(:category2) do
        category_file = category_model.new(cur_site: site, cur_space: space, cur_form: category_form)
        category_file.send("col_#{category_name_column.id}_translations=", category2_name_translations)
        category_file.send("col_#{category_workflow_state_column.id}=", [ category_workflow_state_column.select_options.sample ])
        category_file.save!
        category_model.find(category_file.id)
      end

      context "when reference_type is 'one_to_one'" do
        let(:reference_type) { "one_to_one" }

        context "with actual value" do
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s ])
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expected = [ category1.id, category1_name_translations[I18n.default_locale] ].join("_")
            expect(text).to eq expected
          end
        end

        context "with nil value" do
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_model.create!(cur_site: site, cur_space: space, cur_form: category_form)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expect(text).to be_blank
          end
        end

        context "when category name is unique" do
          let(:category_name_unique_state) { "enabled" }
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s ])
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expect(text).to eq category1_name_translations[I18n.default_locale]
          end
        end

        context "when workflow_state is enabled" do
          let(:workflow_state) { "enabled" }
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s ])
            recycle_item_file.destination_treat_state = "no_need_to_treat"
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expected = [ category1.id, category1_name_translations[I18n.default_locale] ].join("_")
            expect(text).to eq expected
          end
        end
      end

      context "when reference_type is 'one_to_many'" do
        let(:reference_type) { "one_to_many" }

        context "with actual value" do
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s, category2.id.to_s ])
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expected = [
              [ category1.id, category1_name_translations[I18n.default_locale] ].join("_"),
              [ category2.id, category2_name_translations[I18n.default_locale] ].join("_")
            ].join("\n")
            expect(text).to eq expected
          end
        end

        context "with nil value" do
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_model.create!(cur_site: site, cur_space: space, cur_form: category_form)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expect(text).to be_blank
          end
        end

        context "when category name is unique" do
          let(:category_name_unique_state) { "enabled" }
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s, category2.id.to_s ])
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expected = [
              category1_name_translations[I18n.default_locale],
              category2_name_translations[I18n.default_locale]
            ].join("\n")
            expect(text).to eq expected
          end
        end

        context "when workflow_state is enabled" do
          let(:workflow_state) { "enabled" }
          let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
          let!(:recycle_item1) do
            recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
            recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
            recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s, category2.id.to_s ])
            recycle_item_file.destination_treat_state = "no_need_to_treat"
            recycle_item_file.save!
            recycle_item_model.find(recycle_item_file.id)
          end

          it do
            text = recycle_item1.read_csv_value(recycle_item_category_column)
            expected = [
              [ category1.id, category1_name_translations[I18n.default_locale] ].join("_"),
              [ category2.id, category2_name_translations[I18n.default_locale] ].join("_")
            ].join("\n")
            expect(text).to eq expected
          end
        end
      end
    end
  end
end
