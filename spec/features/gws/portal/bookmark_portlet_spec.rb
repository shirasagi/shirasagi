require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  before do
    login_gws_user
  end

  context "not registered bookmarks" do
    let(:basename) { ::Gws::Bookmark::Folder.default_root_name }

    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.bookmark.name')
      end
      within 'form#item-form' do
        wait_cbox_open { click_on I18n.t("gws/share.apis.folders.index") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on basename }
      end
      within 'form#item-form' do
        expect(page).to have_css(".ajax-selected", text: basename)
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_css('.portlets .portlet-model-bookmark', text: I18n.t('gws/portal.portlets.bookmark.name'))
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
    end
  end

  context "registered bookmarks" do
    let!(:folder) { user.bookmark_root_folder(site) }
    let!(:folder1) { create :gws_bookmark_folder, cur_user: user, in_parent: folder.id, in_basename: unique_id }
    let!(:folder2) { create :gws_bookmark_folder, cur_user: user, in_parent: folder.id, in_basename: unique_id }
    let!(:item1) { create :gws_bookmark_item, cur_user: user, folder: folder1 }
    let!(:item2) { create :gws_bookmark_item, cur_user: user, folder: folder2 }

    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.bookmark.name')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_css('.portlets .portlet-model-bookmark', text: I18n.t('gws/portal.portlets.bookmark.name'))
      within ".portlet-model-bookmark .list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
    end

    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.bookmark.name')
      end
      within 'form#item-form' do
        wait_cbox_open { click_on I18n.t("gws/share.apis.folders.index") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on folder1.name }
      end
      within 'form#item-form' do
        expect(page).to have_css(".ajax-selected", text: folder1.name)
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_css('.portlets .portlet-model-bookmark', text: I18n.t('gws/portal.portlets.bookmark.name'))
      within ".portlet-model-bookmark .list-items" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
    end
  end
end
