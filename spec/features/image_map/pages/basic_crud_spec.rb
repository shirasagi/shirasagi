require 'spec_helper'

describe "image_map_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :image_map_node_page, filename: "image-map", name: "image-map" }
  let(:item) { create(:image_map_page, cur_node: node) }

  let(:index_path) { image_map_pages_path site.id, node }
  let(:new_path) { new_image_map_page_path site.id, node }
  let(:show_path) { image_map_page_path site.id, node, item }
  let(:edit_path) { edit_image_map_page_path site.id, node, item }
  let(:delete_path) { delete_image_map_page_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css("#errorExplanation")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      expect(page).to have_css(".delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
