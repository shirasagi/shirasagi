require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }

  before { login_gws_user }

  describe "set_seen_all" do
    it do
      expect(memo.unseen?(gws_user)).to be_truthy

      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t('gws/memo/message.links.etc')
        page.accept_confirm do
          click_on I18n.t('gws/memo/message.links.set_seen')
        end
      end
      wait_for_notice I18n.t('ss.notice.set_seen')

      expect(page).to have_css(".list-item.seen", text: memo.name)
      memo.reload
      expect(memo.unseen?(gws_user)).to be_falsey
    end
  end

  describe "unset_seen_all" do
    it do
      memo.set_seen(gws_user).save!
      expect(memo.unseen?(gws_user)).to be_falsey

      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        click_on I18n.t('gws/memo/message.links.etc')
        page.accept_confirm do
          click_on I18n.t('gws/memo/message.links.unset_seen')
        end
      end
      wait_for_notice I18n.t('ss.notice.unset_seen')

      expect(page).to have_css(".list-item.unseen", text: memo.name)
      memo.reload
      expect(memo.unseen?(gws_user)).to be_truthy
    end
  end

  describe "set_seen_from_popup" do
    let(:portal_path) { gws_portal_path site }

    it do
      visit portal_path

      first(".gws-memo-message.popup-notice-container").click
      wait_for_js_ready
      within ".gws-memo-message.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item", text: memo.name)
        end
        click_on I18n.t("ss.links.more_all")
      end
      wait_for_js_ready

      within ".gws-memos-index" do
        within ".list-items" do
          expect(page).to have_css(".list-item.unseen", text: memo.subject)
        end
      end
    end

    it do
      visit portal_path

      first(".gws-memo-message.popup-notice-container").click
      wait_for_js_ready
      within ".gws-memo-message.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item", text: memo.name)
        end
        page.accept_confirm(I18n.t("gws/notice.confirm.set_seen")) do
          click_on I18n.t("gws/notice.links.set_seen_all")
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen")

      first(".gws-memo-message.popup-notice-container").click
      wait_for_js_ready
      within ".gws-memo-message.popup-notice-container" do
        within ".popup-notice-items" do
          expect(page).to have_css(".list-item.empty", text: I18n.t("gws/memo/message.notice.no_recents"))
        end
        click_on I18n.t("ss.links.more_all")
      end
      wait_for_js_ready

      within ".gws-memos-index" do
        within ".list-items" do
          expect(page).to have_css(".list-item.seen", text: memo.subject)
        end
      end
    end
  end
end
