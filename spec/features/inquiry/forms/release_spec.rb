require 'spec_helper'

describe "inquiry_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :inquiry_node_form }
  let(:edit_path) { edit_cms_node_path site.id, item }

  let(:release_date1) { Time.zone.today.advance(days: 1).strftime("%Y/%m/%d %H:%M") }

  let(:close_date1) { Time.zone.today.advance(days: 2).strftime("%Y/%m/%d %H:%M") }

  context "with auth" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      ensure_addon_opened("#addon-cms-agents-addons-release")
      within "form#item-form" do
        select I18n.t("ss.options.state.public"), from: "item[state]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-cms-agents-addons-release" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      ensure_addon_opened("#addon-cms-agents-addons-release")
      within "form#item-form" do
        select I18n.t("ss.options.state.closed"), from: "item[state]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-cms-agents-addons-release" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.closed"))
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      ensure_addon_opened("#addon-cms-agents-addons-release_plan")
      within "form#item-form" do
        fill_in "item[release_date]", with: release_date1
      end
      ensure_addon_opened("#addon-cms-agents-addons-release")
      within "form#item-form" do
        select I18n.t("ss.options.state.public"), from: "item[state]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-cms-agents-addons-release" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.ready"))
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      ensure_addon_opened("#addon-cms-agents-addons-release_plan")
      within "form#item-form" do
        fill_in "item[close_date]", with: close_date1
      end
      ensure_addon_opened("#addon-cms-agents-addons-release")
      within "form#item-form" do
        select I18n.t("ss.options.state.public"), from: "item[state]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-cms-agents-addons-release" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
      end
    end
  end
end
