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

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.set_seen'))
      end

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

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.unset_seen'))
      end

      expect(page).to have_css(".list-item.unseen", text: memo.name)
      memo.reload
      expect(memo.unseen?(gws_user)).to be_truthy
    end
  end
end
