require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder, comment_state: "enabled", deleted: Time.zone.now }

  before { login_gws_user }

  describe "restore" do
    it do
      visit gws_notice_main_path(site: site)
      click_on I18n.t("ss.navi.trash")
      wait_for_js_ready
      click_on item.name
      wait_for_js_ready
      click_on I18n.t("ss.links.restore")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.restore")
      end
      wait_for_notice I18n.t('ss.notice.restored')

      item.reload
      expect(item.deleted).to be_blank

      visit gws_notice_main_path(site: site)
      expect(page).to have_css("#content-navi .content-navi-refresh", text: "refresh")
      expect(page).to have_css(".list-item", text: item.name)
    end
  end

  describe "hard delete" do
    it do
      visit gws_notice_main_path(site: site)
      click_on I18n.t("ss.navi.trash")
      wait_for_js_ready
      click_on item.name
      wait_for_js_ready
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  describe "hard delete all" do
    it do
      visit gws_notice_main_path(site: site)
      click_on I18n.t("ss.navi.trash")
      wait_for_js_ready

      within ".list-head" do
        wait_event_to_fire("ss:checked-all-list-items") { first("input[type='checkbox']").click }
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
