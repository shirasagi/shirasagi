require 'spec_helper'

describe 'gws_memo_messages', type: :request, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }

  context 'with auth', js: true do
    before { login_gws_user }

    it '#index' do
      visit gws_memo_messages_path(site)
      wait_for_ajax
      expect(status_code).to eq 200
    end

    it '#new' do
      visit new_gws_memo_message_path(site)
      wait_for_ajax
      expect(status_code).to eq 200
    end

    it '#show' do
      visit gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(status_code).to eq 200
    end

    it '#edit' do
      visit edit_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(status_code).to eq 200
    end

    it '#trash' do
      visit trash_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(status_code).to eq 200
    end

    it '#toggle_star' do
      visit toggle_star_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(status_code).to eq 200
    end

    it '#trash_all' do
      post trash_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      expect(status_code).to eq 200
    end

    it '#set_seen_all' do
      post set_seen_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      expect(status_code).to eq 200
    end

    it '#unset_seen_all' do
      post unset_seen_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      expect(status_code).to eq 200
    end

    it '#set_star_all' do
      post set_star_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      expect(status_code).to eq 200
    end

    it '#unset_star_all' do
      post unset_star_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      expect(status_code).to eq 200
    end

    it '#move_all' do
      post move_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id], path: 'INBOX.Trash'
      expect(status_code).to eq 200
    end
  end
end
