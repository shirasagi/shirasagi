require 'spec_helper'

describe Gws::Tabular::File::CsvExporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:space) { create :gws_tabular_space, cur_site: site }
  let!(:category_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:category_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: category_form, order: 10,
      input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled")
  end
  let!(:category_workflow_state_column) do
    create(:gws_tabular_column_enum_field, cur_site: site, cur_form: category_form, order: 20)
  end
  let!(:recycle_item_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:recycle_item_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: recycle_item_form, order: 10,
      input_type: "single", max_length: nil, validation_type: "none", i18n_state: "enabled")
  end
  let!(:recycle_item_category_column) do
    create(
      :gws_tabular_column_reference_field, cur_site: site, cur_form: recycle_item_form, order: 20,
      reference_form: category_form, reference_type: "one_to_one"
    )
  end
  let!(:recycle_item_category_name_column) do
    create(
      :gws_tabular_column_lookup_field, cur_site: site, cur_form: recycle_item_form, order: 30,
      reference_column: recycle_item_category_column, lookup_column: category_name_column
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

  context "export" do
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

    let!(:recycle_item_model) { Gws::Tabular::File[recycle_item_form.current_release] }
    let!(:recycle_item1) do
      recycle_item_file = recycle_item_model.new(cur_site: site, cur_space: space, cur_form: recycle_item_form)
      recycle_item_file.send("col_#{recycle_item_name_column.id}_translations=", i18n_translations(prefix: "item"))
      recycle_item_file.send("col_#{recycle_item_category_column.id}_ids=", [ category1.id.to_s ])
      recycle_item_file.save!
      recycle_item_model.find(recycle_item_file.id)
    end

    it do
      criteria = recycle_item_model.site(site).allow(:read, user, site: site)
      exporter = Gws::Tabular::File::CsvExporter.new(
        site: site, user: user, space: space, form: recycle_item_form,
        release: recycle_item_form.current_release, criteria: criteria)
      csv = exporter.enum_csv(encoding: "UTF-8").to_a.join
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv), headers: true) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[recycle_item_model.t(:id)]).to eq recycle_item1.id.to_s
            "#{recycle_item_category_name_column.name} (#{I18n.t("ss.options.lang.ja")})".tap do |ja_column_name|
              expect(csv_row[ja_column_name]).to eq category1_name_translations[:ja]
            end
            "#{recycle_item_category_name_column.name} (#{I18n.t("ss.options.lang.en")})".tap do |en_column_name|
              expect(csv_row[en_column_name]).to eq category1_name_translations[:en]
            end
          end
        end
      end
    end
  end
end
