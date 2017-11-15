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
      expect(page).to have_content('受信トレイ')
    end

    it '#new' do
      visit new_gws_memo_message_path(site)
      wait_for_ajax
      expect(page).to have_content('参加者')
    end

    it '#show' do
      visit gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content(memo.name)
    end

    it '#edit' do
      visit edit_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      wait_for_ajax
      expect(page).to have_content('参加者')
    end

    it '#trash' do
      visit trash_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content('ゴミ箱 (1)')
    end

    it '#toggle_star' do
      visit toggle_star_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content(memo.name)
    end

    it '#trash_all' do
      post trash_all_gws_memo_messages_path(site: site, folder: 'INBOX'), ids: [memo.id]
      wait_for_ajax
      expect(page).to have_content('ゴミ箱 (1)')
    end

    it '#set_seen_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button "その他"
        find('.set_seen_all').click
      end
      wait_for_ajax
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
