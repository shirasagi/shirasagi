require 'spec_helper'

describe "gws_notices_back_numbers", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:folder) { create(:gws_notice_folder, cur_site: site) }

  let(:browsed) { { admin.id => Time.zone.now.utc } }
  let!(:item1) do
    create(:gws_notice_post, cur_site: site, folder: folder, close_date: now - 1.day)
  end
  let!(:item2) do
    create(:gws_notice_post, cur_site: site, folder: folder, severity: "high", close_date: now - 1.day)
  end
  let!(:item3) do
    create(:gws_notice_post, cur_site: site, folder: folder, browsed_users_hash: browsed, close_date: now - 1.day)
  end
  let!(:item4) do
    create(
      :gws_notice_post, cur_site: site, folder: folder, severity: "high", browsed_users_hash: browsed,
      close_date: now - 1.day)
  end

  before do
    site.notice_browsed_state = "both"
    site.update!
  end

  context "with auth" do
    context "default toggled by button" do
      it "#index" do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        page.accept_confirm do
          click_on I18n.t("gws/notice.links.set_seen")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.read", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.ss-tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end
    end

    context "default toggled by read" do
      before do
        site.notice_toggle_browsed = "read"
        site.update!
      end

      it "#index" do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        expect(page).to have_button(I18n.t("gws/notice.links.unset_seen"))
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.read", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.ss-tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end

      it "#index" do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        expect(page).to have_button(I18n.t("gws/notice.links.unset_seen"))

        page.accept_confirm do
          click_on I18n.t("gws/notice.links.unset_seen")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        wait_for_all_turbo_frames
        within '.gws-notice-folder' do
          expect(page).to have_css('.ss-tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end
    end
  end
end
