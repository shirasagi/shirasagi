require 'spec_helper'

describe "lsorg_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node1) { create :lsorg_node_node }
  let!(:node2) { create :lsorg_node_page, cur_node: node1 }
  let!(:item) { create :lsorg_node_page, cur_node: node2 }

  let(:name) { unique_id }
  let(:basename) { "basename" }

  let(:index_path) { lsorg_pages_path(site: site, cid: node2) }
  let(:new_path) { new_lsorg_page_path(site: site, cid: node2) }
  let(:show_path) { lsorg_page_path(site: site, cid: node2, id: item) }
  let(:edit_path) { edit_lsorg_page_path(site: site, cid: node2, id: item) }
  let(:delete_path) { delete_lsorg_page_path(site: site, cid: node2, id: item) }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      within ".list-items" do
        expect(page).to have_link item.name
      end
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      within "#addon-basic" do
        expect(page).to have_text name
        expect(page).to have_text basename
      end
    end

    it "#show" do
      visit show_path
      within "#addon-basic" do
        expect(page).to have_text item.name
        expect(page).to have_text item.basename
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      within "#addon-basic" do
        expect(page).to have_text name
      end
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end
end