require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:folder) { create(:gws_notice_folder) }

  let(:browsed) { { user.id => Time.zone.now.utc } }
  let!(:item1) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: Time.zone.now }
  let!(:item2) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: item1.released + 1.day }
  let!(:item3) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: item2.released + 1.day }
  let!(:item4) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: item3.released + 1.day }
  let!(:item5) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: item4.released + 1.day }
  let!(:item6) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed, released: item5.released + 1.day }

  let!(:item7) { create :gws_notice_post, folder: folder, released: item6.released + 1.day }
  let!(:item8) { create :gws_notice_post, folder: folder, released: item7.released + 1.day }
  let!(:item9) { create :gws_notice_post, folder: folder, released: item8.released + 1.day }
  let!(:item10) { create :gws_notice_post, folder: folder, released: item9.released + 1.day }
  let!(:item11) { create :gws_notice_post, folder: folder, released: item10.released + 1.day }
  let!(:item12) { create :gws_notice_post, folder: folder, released: item11.released + 1.day }

  before do
    login_gws_user
  end

  context "default unread" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.notice.name')
      end
      within 'form#item-form' do
        click_link I18n.t('gws/share.apis.folders.index')
      end
      wait_for_cbox do
        click_link folder.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_portal_user_path(site: site, user: user)
      within ".portlets .gws-notices" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
        expect(page).to have_no_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".portlets .gws-notices" do
        click_on I18n.t("ss.links.more")
      end
      within ".index.gws-notices" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
        expect(page).to have_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
    end
  end

  context "default both" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.notice.name')
      end
      within 'form#item-form' do
        select I18n.t('gws/board.options.browsed_state.both'), from: "item[notice_browsed_state]"
        click_link I18n.t('gws/share.apis.folders.index')
      end
      wait_for_cbox do
        click_link folder.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_portal_user_path(site: site, user: user)
      within ".portlets .gws-notices" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
        expect(page).to have_no_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".portlets .gws-notices" do
        click_on I18n.t("ss.links.more")
      end
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
        expect(page).to have_css(".list-item", text: item5.name)
        expect(page).to have_css(".list-item", text: item6.name)
        expect(page).to have_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
    end
  end

  context "default read" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.notice.name')
      end
      within 'form#item-form' do
        select I18n.t('gws/board.options.browsed_state.read')
        click_link I18n.t('gws/share.apis.folders.index')
      end
      wait_for_cbox do
        click_link folder.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_portal_user_path(site: site, user: user)
      within ".portlets .gws-notices" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
        expect(page).to have_css(".list-item", text: item5.name)
        expect(page).to have_css(".list-item", text: item6.name)
        expect(page).to have_no_css(".list-item", text: item7.name)
        expect(page).to have_no_css(".list-item", text: item8.name)
        expect(page).to have_no_css(".list-item", text: item9.name)
        expect(page).to have_no_css(".list-item", text: item10.name)
        expect(page).to have_no_css(".list-item", text: item11.name)
        expect(page).to have_no_css(".list-item", text: item12.name)
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".portlets .gws-notices" do
        click_on I18n.t("ss.links.more")
      end
      within ".index.gws-notices" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
        expect(page).to have_css(".list-item", text: item5.name)
        expect(page).to have_css(".list-item", text: item6.name)
        expect(page).to have_no_css(".list-item", text: item7.name)
        expect(page).to have_no_css(".list-item", text: item8.name)
        expect(page).to have_no_css(".list-item", text: item9.name)
        expect(page).to have_no_css(".list-item", text: item10.name)
        expect(page).to have_no_css(".list-item", text: item11.name)
        expect(page).to have_no_css(".list-item", text: item12.name)
      end
    end
  end
end
