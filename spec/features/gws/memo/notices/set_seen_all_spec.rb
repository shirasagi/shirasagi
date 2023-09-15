require 'spec_helper'

describe 'gws/memo/notices', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:circular_item) { create(:gws_circular_post, :gws_circular_posts) }
  let(:circular_path) { gws_circular_post_path(site: site, category: '-', id: circular_item) }
  let!(:item1) do
    SS::Notification.create!(
      cur_group: site, cur_user: user,
      subject: "subject-#{unique_id}", format: "text", text: "text-#{unique_id}" * 10,
      member_ids: [user.id], state: "public"
    )
  end
  let!(:item2) do
    SS::Notification.create!(
      cur_group: site, cur_user: user,
      subject: "subject-#{unique_id}", format: "text", text: "", url: circular_path,
      member_ids: [user.id], state: "public"
    )
  end
  let!(:item3) do
    SS::Notification.create!(
      cur_group: site, cur_user: user,
      subject: "subject-#{unique_id}", format: "text", text: "",
      member_ids: [user.id], state: "public"
    )
  end

  before { login_gws_user }

  context "index" do
    let(:index_path) { gws_memo_notices_path site }

    it do
      visit index_path

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_css(".list-item.unseen", text: item1.subject)
          expect(page).to have_css(".list-item.unseen", text: item2.subject)
          expect(page).to have_css(".list-item.unseen", text: item3.subject)
        end
        within ".list-head" do
          wait_event_to_fire("ss:checked-all-list-items") { find('label.check input').set(true) }
          page.accept_confirm(I18n.t("gws/notice.confirm.set_seen")) do
            click_on I18n.t("gws/notice.links.set_seen")
          end
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_css(".list-item.seen", text: item1.subject)
          expect(page).to have_css(".list-item.seen", text: item2.subject)
          expect(page).to have_css(".list-item.seen", text: item3.subject)
        end
      end
    end

    it do
      visit index_path

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_css(".list-item.unseen", text: item1.subject)
          expect(page).to have_css(".list-item.unseen", text: item2.subject)
          expect(page).to have_css(".list-item.unseen", text: item3.subject)
        end
        within ".list-items" do
          first('label.check input').set(true)
        end
        within ".list-head" do
          page.accept_confirm(I18n.t("gws/notice.confirm.set_seen")) do
            click_on I18n.t("gws/notice.links.set_seen")
          end
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_selector(".list-item.unseen", count: 2)
          expect(page).to have_selector(".list-item.seen", count: 1)
        end
      end
    end
  end

  context "popup" do
    let(:portal_path) { gws_portal_path site }

    it do
      visit portal_path

      first(".gws-memo-notice.popup-notice-container").click
      within ".gws-memo-notice.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item", text: item1.subject)
          expect(page).to have_css(".list-item", text: item2.subject)
          expect(page).to have_css(".list-item", text: item3.subject)
        end
        click_on I18n.t("ss.links.more_all")
      end
      wait_for_js_ready

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_css(".list-item.unseen", text: item1.subject)
          expect(page).to have_css(".list-item.unseen", text: item2.subject)
          expect(page).to have_css(".list-item.unseen", text: item3.subject)
        end
      end
    end

    it do
      visit portal_path

      first(".gws-memo-notice.popup-notice-container").click
      within ".gws-memo-notice.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item", text: item1.subject)
          expect(page).to have_css(".list-item", text: item2.subject)
          expect(page).to have_css(".list-item", text: item3.subject)
        end
        page.accept_confirm(I18n.t("gws/notice.confirm.set_seen")) do
          click_on I18n.t("gws/notice.links.set_seen_all")
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      first(".gws-memo-notice.popup-notice-container").click
      wait_for_js_ready
      within ".gws-memo-notice.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item.empty", text: I18n.t("gws/memo/message.notice.no_recents"))
        end
        click_on I18n.t("ss.links.more_all")
      end
      wait_for_js_ready

      within ".gws-memo-notices" do
        within ".list-items" do
          expect(page).to have_css(".list-item.seen", text: item1.subject)
          expect(page).to have_css(".list-item.seen", text: item2.subject)
          expect(page).to have_css(".list-item.seen", text: item3.subject)
        end
      end
    end
  end
end
