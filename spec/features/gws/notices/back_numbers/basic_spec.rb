require 'spec_helper'

describe "gws_notices_back_numbers", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:folder) { create(:gws_notice_folder, cur_site: site, cur_user: admin) }

  let(:browsed) { { admin.id => Time.zone.now.utc } }
  let!(:item1) { create(:gws_notice_post, cur_site: site, folder: folder, close_date: now - 1.day) }
  let!(:item2) { create(:gws_notice_post, cur_site: site, folder: folder, severity: "high", close_date: now - 1.day) }
  let!(:item3) do
    create(:gws_notice_post, cur_site: site, folder: folder, browsed_users_hash: browsed, close_date: now - 1.day)
  end
  let!(:item4) do
    create(
      :gws_notice_post, cur_site: site, folder: folder, severity: "high", browsed_users_hash: browsed,
      close_date: now - 1.day)
  end

  context "with site's notice_severity" do
    context "is blank (default)" do
      before do
        site.unset(:notice_severity)
        site.unset(:notice_browsed_state)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
      end
    end

    context "is 'all'" do
      before do
        site.notice_severity = "all"
        site.update!
        site.unset(:notice_browsed_state)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
      end
    end

    context "is 'high'" do
      before do
        site.notice_severity = "high"
        site.update!
        site.unset(:notice_browsed_state)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/notice.options.severity.all"), from: "s[severity]"
          click_on I18n.t("ss.buttons.search")
        end
        # wait for ajax completion
        wait_for_all_turbo_frames

        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
      end
    end

    context "is 'normal'" do
      before do
        site.notice_severity = "normal"
        site.update!
        site.unset(:notice_browsed_state)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/notice.options.severity.all"), from: "s[severity]"
          click_on I18n.t("ss.buttons.search")
        end
        # wait for ajax completion
        wait_for_all_turbo_frames

        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
      end
    end
  end

  context "with site's notice_browsed_state" do
    context "is blank (default)" do
      before do
        site.unset(:notice_severity)
        site.unset(:notice_browsed_state)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end

    context "is 'both'" do
      before do
        site.notice_browsed_state = "both"
        site.update!
        site.unset(:notice_severity)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end

    context "is 'unread'" do
      before do
        site.notice_browsed_state = "unread"
        site.update!
        site.unset(:notice_severity)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/board.options.browsed_state.both"), from: "s[browsed_state]"
          click_on I18n.t("ss.buttons.search")
        end
        # wait for ajax completion
        wait_for_all_turbo_frames

        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end

    context "is 'read'" do
      before do
        site.notice_browsed_state = "read"
        site.update!
        site.unset(:notice_severity)
      end

      it do
        login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: folder, category_id: '-')
        wait_for_all_turbo_frames
        expect(page).to have_css("#content-navi-core .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", count: 2)
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/board.options.browsed_state.both"), from: "s[browsed_state]"
          click_on I18n.t("ss.buttons.search")
        end
        # wait for ajax completion
        wait_for_all_turbo_frames

        expect(page).to have_css(".list-item", count: 4)
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end
  end
end
