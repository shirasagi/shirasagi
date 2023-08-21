require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }

  before { login_gws_user }

  describe "trash_all" do
    it do
      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t('gws/memo/message.links.trash')
        end
      end

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.deleted'))
      end

      memo.reload
      expect(memo.path(gws_user)).to eq "INBOX.Trash"

      within ".gws-memo-folder" do
        click_on I18n.t('gws/memo/folder.inbox_trash')
      end
      expect(page).to have_css(".list-item", text: memo.name)

      # try to delete
      first(".list-item input[type=checkbox]").click
      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t('ss.links.delete')
        end
      end

      within find("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.deleted'))
      end

      expect(Gws::Memo::Message.site(site).member(gws_user).where(id: memo.id)).to be_blank
      memo.reload
      expect(memo.user_settings.find { |setting| setting['user_id'] == gws_user.id }).to be_nil
    end
  end
end
