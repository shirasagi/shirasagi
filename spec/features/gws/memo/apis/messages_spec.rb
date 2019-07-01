require 'spec_helper'

describe "gws_memo_apis_messages", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let(:user2) { create(:gws_user) }
  let(:path) { gws_memo_apis_messages_path site }
  let!(:memo) { create(:gws_memo_message, user: user2, site: site, in_to_members: [user1.id.to_s]) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: user1, site: site, in_to_members: [user2.id.to_s]) }
  let!(:sent_memo) { create(:gws_memo_message, user: user1, site: site, in_to_members: [user2.id.to_s]) }

  context "with auth" do
    before { login_gws_user }

    it "index" do
      visit path
      expect(page).to have_content(memo.subject)
      expect(page).to have_no_content(draft_memo.subject)
      expect(page).to have_no_content(sent_memo.subject)

      select I18n.t('gws/memo/folder.inbox_draft')
      click_button I18n.t('ss.buttons.search')
      expect(page).to have_no_content(memo.subject)
      expect(page).to have_content(draft_memo.subject)
      expect(page).to have_no_content(sent_memo.subject)

      select I18n.t('gws/memo/folder.inbox_sent')
      click_button I18n.t('ss.buttons.search')
      expect(page).to have_no_content(memo.subject)
      expect(page).to have_no_content(draft_memo.subject)
      expect(page).to have_content(sent_memo.subject)
    end
  end
end
