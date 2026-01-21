require 'spec_helper'

# ルックアップ型が検索対象にならない
describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:now) { Time.zone.now.change(sec: 0) }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }

  let!(:class_form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1
  end
  let!(:class_name_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: class_form, order: 10, required: "required",
      input_type: "single", validation_type: "none", i18n_state: "disabled", unique_state: "enabled")
  end
  let!(:class_memo_column) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: class_form, order: 20, required: "required",
      input_type: "single", validation_type: "none", i18n_state: "enabled", unique_state: "disabled")
  end

  let!(:item_form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1, readable_setting_range: "public",
      workflow_state: 'disabled')
  end
  let!(:item_class_column) do
    create(
      :gws_tabular_column_reference_field, cur_site: site, cur_form: item_form, order: 10, required: "required",
      reference_form: class_form, reference_type: "one_to_one"
    )
  end
  let!(:item_class_memo_lookup_column) do
    create(
      :gws_tabular_column_lookup_field, cur_site: site, cur_form: item_form, order: 20,
      reference_column: item_class_column, lookup_column: class_memo_column, index_state: 'asc'
    )
  end

  context "keyword search with lookup column" do
    let(:class_name1) { "class-name-#{unique_id}" }
    let(:class_memo1_translations) { i18n_translations(prefix: "class-memo") }
    let(:class_name2) { "class-name-#{unique_id}" }
    let(:class_memo2_translations) { i18n_translations(prefix: "class-memo") }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      ActionMailer::Base.deliveries.clear

      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(class_form.id.to_s)
      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(item_form.id.to_s)

      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      class_form.reload
      class_model = Gws::Tabular::File[class_form.current_release]
      class_name_file1 = class_model.new(cur_site: site, cur_space: space, cur_form: class_form)
      class_name_file1.send("col_#{class_name_column.id}=", class_name1)
      class_name_file1.send("col_#{class_memo_column.id}_translations=", class_memo1_translations)
      class_name_file1.save!

      class_name_file2 = class_model.new(cur_site: site, cur_space: space, cur_form: class_form)
      class_name_file2.send("col_#{class_name_column.id}=", class_name2)
      class_name_file2.send("col_#{class_memo_column.id}_translations=", class_memo2_translations)
      class_name_file2.save!

      item_form.reload
    end

    after { ActionMailer::Base.deliveries.clear }

    it do
      login_user admin
      visit gws_tabular_spaces_path(site: site)
      wait_for_js_ready
      within ".list-items" do
        click_on space.i18n_name
      end
      wait_for_all_turbo_frames
      within ".current-navi" do
        click_on item_form.i18n_name
      end
      wait_for_all_turbo_frames
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      wait_for_all_turbo_frames
      within "form#item-form" do
        wait_for_cbox_opened { click_on I18n.t("gws/tabular.apis.files.index", name: class_form.i18n_name) }
      end
      within_cbox do
        wait_for_cbox_closed { click_on class_name1 }
      end
      within "form#item-form" do
        expect(page).to have_css("[data-column-id='#{item_class_column.id}']", text: class_name1)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_turbo_frames

      within ".current-navi" do
        click_on item_form.i18n_name
      end
      wait_for_all_turbo_frames
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      wait_for_all_turbo_frames
      within "form#item-form" do
        wait_for_cbox_opened { click_on I18n.t("gws/tabular.apis.files.index", name: class_form.i18n_name) }
      end
      within_cbox do
        wait_for_cbox_closed { click_on class_name2 }
      end
      within "form#item-form" do
        expect(page).to have_css("[data-column-id='#{item_class_column.id}']", text: class_name2)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_turbo_frames

      item_model = Gws::Tabular::File[item_form.current_release]
      expect(item_model.count).to eq 2
      item_files = item_model.all.to_a
      item_file1 = item_files[0]
      item_file1.read_tabular_value(item_class_column).first.tap do |item_class_value|
        expect(item_class_value).to be_present
        expect(item_class_value.read_tabular_value(class_name_column)).to eq class_name1
      end
      expect(item_file1.read_tabular_value(item_class_memo_lookup_column)).to eq [ class_memo1_translations ]

      item_file2 = item_files[1]
      item_file2.read_tabular_value(item_class_column).first.tap do |item_class_value|
        expect(item_class_value).to be_present
        expect(item_class_value.read_tabular_value(class_name_column)).to eq class_name2
      end
      expect(item_file2.read_tabular_value(item_class_memo_lookup_column)).to eq [ class_memo2_translations ]

      within ".current-navi" do
        click_on item_form.i18n_name
      end
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id]", count: 2)
      expect(page).to have_css(".list-item[data-id='#{item_file1.id}']")
      expect(page).to have_css(".list-item[data-id='#{item_file2.id}']")

      within "form.index-search" do
        fill_in "s[keyword]", with: class_memo2_translations[I18n.locale]
        click_on I18n.t("ss.buttons.search")
      end
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{item_file2.id}']")

      within "form.index-search" do
        fill_in "s[keyword]", with: class_memo1_translations[I18n.locale]
        click_on I18n.t("ss.buttons.search")
      end
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id]", count: 1)
      expect(page).to have_css(".list-item[data-id='#{item_file1.id}']")

      within "form.index-search" do
        fill_in "s[keyword]", with: class_name2
        click_on I18n.t("ss.buttons.search")
      end
      wait_for_all_turbo_frames
      expect(page).to have_css(".list-item[data-id]", count: 0)
    end
  end
end
