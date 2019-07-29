require 'spec_helper'

describe 'gws_memo_messages_redirect_to_appropriate_folder', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let!(:user2) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:memo) { create(:gws_memo_message, user: user2, site: site) }
  let!(:sent_memo) { create(:gws_memo_message, site: site, in_to_members: [user2.id.to_s]) }
  let!(:trash_memo) { create(:gws_memo_message, user: user2, site: site, in_path: { user1.id.to_s => 'INBOX.Trash' }) }

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit gws_memo_message_path(site, folder: 'REDIRECT', id: memo.id)
      expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX', id: memo.id)

      visit gws_memo_message_path(site, folder: 'REDIRECT', id: sent_memo.id)
      expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX.Sent', id: sent_memo.id)

      visit gws_memo_message_path(site, folder: 'REDIRECT', id: trash_memo.id)
      expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX.Trash', id: trash_memo.id)
    end
  end
end
