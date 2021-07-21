require 'spec_helper'

describe "facility_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :facility_node_page, name: "facility" }
  let(:item) { create(:facility_notice, cur_node: node) }

  let(:index_path) { facility_notices_path site, node }
  let(:new_path) { new_facility_notice_path site, node }
  let(:show_path) { facility_notice_path site, node, item }
  let(:edit_path) { edit_facility_notice_path site, node, item }
  let(:delete_path) { delete_facility_notice_path site, node, item }

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
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
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
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
