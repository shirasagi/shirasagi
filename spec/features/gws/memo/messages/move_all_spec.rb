require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:folder) { create(:gws_memo_folder, user: user, site: site) }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }

  before { login_gws_user }

  describe "move_all" do
    it do
      expect(memo.unseen?(gws_user)).to be_truthy

      visit gws_memo_messages_path(site)
      first(".list-item input[type=checkbox]").click
      within ".move-menu" do
        click_on I18n.t('gws/memo/message.links.move')
        page.accept_confirm do
          click_on folder.name
        end
      end
      wait_for_notice I18n.t('ss.notice.move_all')

      memo.reload
      expect(memo.path(gws_user)).to eq folder.id.to_s

      within ".gws-memo-folder" do
        click_on folder.name
      end
      expect(page).to have_css(".list-item", text: memo.name)
    end
  end
end
