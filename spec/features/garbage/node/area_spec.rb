require 'spec_helper'

describe "garbage_node_areas", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }

  let!(:search_node) do
    create(
      :garbage_node_search,
      filename: "search",
      st_category_ids: [category1.id, category2.id]
    )
  end
  let!(:node) do
    create(
      :garbage_node_area_list,
      filename: "search/list",
    )
  end

  let!(:category1) { create :garbage_node_category, name: "category1"}
  let!(:category2) { create :garbage_node_category, name: "category2"}

  let!(:item) do
    create(
      :garbage_node_area,
      name: "item",
      filename: "search/list/item",
    )
  end

  let(:index_path) { garbage_area_lists_path site.id, node }
  let(:new_path) { new_garbage_area_list_path site.id, node }
  let(:show_path) { garbage_area_path site.id, node, item }
  let(:edit_path) { edit_garbage_area_list_path site.id, node, item }
  let(:delete_path) { delete_garbage_area_list_path site.id, node, item }
  let(:import_path) { import_garbage_area_lists_path site.id, node }
  let(:area_edit_path) { edit_garbage_area_path site.id, area_node, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
    end

    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')
      expect(current_path).not_to eq sns_login_path
    end

    it "#import" do
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/garbage/garbage_pages.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end

    it "#garbage_type" do
      visit edit_path
      within "form#item-form" do
        select category1.name, from: "item_garbage_type__field"
        fill_in "item[garbage_type][][value]", with: "月"
        fill_in "item[garbage_type][][view]", with: "毎週月曜日"
        click_button I18n.t('ss.buttons.save')
      end
      item.reload
      expect(item.garbage_type.length).to eq 1
      expect(page).to have_content item.garbage_type.first[:field]
      expect(page).to have_content item.garbage_type.first[:value]
      expect(page).to have_content item.garbage_type.first[:view]

      visit edit_path
      within "form#item-form" do
        find(".add-info").click
        all("#item_garbage_type__field").last.select category2.name
        all("#item_garbage_type__value").last.set "火"
        all("#item_garbage_type__view").last.set "毎週火曜日"
        click_button I18n.t('ss.buttons.save')
      end
      item.reload
      expect(item.garbage_type.length).to eq 2
      expect(page).to have_content item.garbage_type.last[:field]
      expect(page).to have_content item.garbage_type.last[:value]
      expect(page).to have_content item.garbage_type.last[:view]

      visit edit_path
      accept_confirm do
        first(".clear").click
      end
      click_button I18n.t('ss.buttons.save')
      item.reload
      expect(item.garbage_type.length).to eq 1
      expect(page).to have_content category2.name
      expect(page).to have_content "火"
      expect(page).to have_content "毎週火曜日"

      visit edit_path
      accept_confirm do
        first(".clear").click
      end
      click_button I18n.t('ss.buttons.save')
      item.reload
      expect(item.garbage_type.length).to eq 0
    end
  end
end
