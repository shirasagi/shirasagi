require 'spec_helper'

describe "inquiry_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :inquiry_node_form }
  let(:edit_path) { edit_cms_node_path site.id, item }

  let(:release_date1) { Time.zone.today.advance(days: 1).strftime("%Y/%m/%d %H:%M") }
  let(:release_date2) { Time.zone.today.advance(days: -2).strftime("%Y/%m/%d %H:%M") }

  let(:close_date1) { Time.zone.today.advance(days: 2).strftime("%Y/%m/%d %H:%M") }
  let(:close_date2) { Time.zone.today.advance(days: -1).strftime("%Y/%m/%d %H:%M") }

  ENSURE_ADDON_OPENED = <<~SCRIPT.freeze
    (function(addonId, resolve) {
      var $addon = $(addonId);
      if (! $addon[0]) {
        resolve(false);
        return;
      }
      if ($addon.hasClass("hide")) {
        resolve(false);
        return;
      }
      if (! $addon.hasClass("body-closed")) {
        resolve(true);
        return;
      }
      $addon.one("ss:addonShown", function() { resolve(true); });
      $addon.find(".toggle-head").trigger("click");
    })(arguments[0], arguments[1]);
  SCRIPT

  def ensure_addon_opened(addon_id)
    result = page.evaluate_async_script(ENSURE_ADDON_OPENED, addon_id)
    expect(result).to be_truthy
    true
  end

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
      ensure_addon_opened("#addon-inquiry-agents-addons-release_plan")
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
      ensure_addon_opened("#addon-inquiry-agents-addons-release_plan")
      within "form#item-form" do
        fill_in "item[release_date]", with: release_date2
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
      ensure_addon_opened("#addon-inquiry-agents-addons-release_plan")
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

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      ensure_addon_opened("#addon-inquiry-agents-addons-release_plan")
      within "form#item-form" do
        fill_in "item[close_date]", with: close_date2
      end
      ensure_addon_opened("#addon-cms-agents-addons-release")
      within "form#item-form" do
        select I18n.t("ss.options.state.public"), from: "item[state]"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-cms-agents-addons-release" do
        expect(page).to have_css("dd", text: I18n.t("ss.options.state.closed"))
      end
    end
  end
end
