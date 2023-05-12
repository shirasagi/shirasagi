require 'spec_helper'

describe "cms/line/test_members", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_test_member }

  let(:name) { unique_id }
  let(:oauth_id) { unique_id }
  let(:order) { 10 }
  let(:default_checked) { I18n.t("ss.options.state.enabled") }

  let(:index_path) { cms_line_test_members_path site }
  let(:new_path) { new_cms_line_test_member_path site }
  let(:show_path) { cms_line_test_member_path site, item }
  let(:edit_path) { edit_cms_line_test_member_path site, item }
  let(:delete_path) { delete_cms_line_test_member_path site, item }

  describe "basic crud" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[oauth_id]", with: oauth_id
        fill_in "item[order]", with: order
        select default_checked, from: "item[default_checked]"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#addon-basic", text: name)
      expect(page).to have_css("#addon-basic", text: oauth_id)
      expect(page).to have_css("#addon-basic", text: order)
      expect(page).to have_css("#addon-basic", text: default_checked)
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(page).to have_css("#addon-basic", text: item.oauth_id)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[oauth_id]", with: "oauth_id"
        fill_in "item[order]", with: order
        select default_checked, from: "item[default_checked]"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#addon-basic", text: "name")
      expect(page).to have_css("#addon-basic", text: "oauth_id")
      expect(page).to have_css("#addon-basic", text: order)
      expect(page).to have_css("#addon-basic", text: default_checked)
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
