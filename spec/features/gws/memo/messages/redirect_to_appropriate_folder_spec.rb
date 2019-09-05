require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let!(:user2) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }

  context "when folder is 'REDIRECT', it redirects browser to appropriate folder" do
    context "with gws/memo/message" do
      let!(:memo) { create(:gws_memo_message, user: user2, site: site) }
      let!(:sent_memo) { create(:gws_memo_message, site: site, in_to_members: [user2.id.to_s]) }
      let!(:trash_memo) { create(:gws_memo_message, user: user2, site: site, in_path: { user1.id.to_s => 'INBOX.Trash' }) }

      before { login_gws_user }

      it do
        visit gws_memo_message_path(site, folder: 'REDIRECT', id: memo.id)
        expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX', id: memo.id)

        visit gws_memo_message_path(site, folder: 'REDIRECT', id: sent_memo.id)
        expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX.Sent', id: sent_memo.id)

        visit gws_memo_message_path(site, folder: 'REDIRECT', id: trash_memo.id)
        expect(current_path).to eq gws_memo_message_path(site, folder: 'INBOX.Trash', id: trash_memo.id)
      end
    end

    context "with gws/memo/list_message" do
      let!(:list) do
        create(:gws_memo_list, cur_site: site, member_ids: [user1.id], user_ids: [user2.id])
      end

      let!(:memo) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user2, list: list, state: 'public'
        )
      end

      let!(:trash_memo) do
        create(
          :gws_memo_list_message, cur_site: site, cur_user: user2, list: list, state: 'public',
          in_path: { user1.id.to_s => 'INBOX.Trash' }
        )
      end

      it do
        login_user user1
        visit gws_memo_message_path(site, folder: 'REDIRECT', id: memo.id)
        expect(current_path).to eq gws_memo_message_path(site: site, folder: 'INBOX', id: memo)

        visit gws_memo_message_path(site, folder: 'REDIRECT', id: trash_memo.id)
        expect(current_path).to eq gws_memo_message_path(site: site, folder: 'INBOX.Trash', id: trash_memo)

        login_user user2
        visit gws_memo_message_path(site, folder: 'REDIRECT', id: memo.id)
        expect(current_path).to eq gws_memo_list_message_path(site: site, list_id: list, id: memo)
      end
    end
  end
end
