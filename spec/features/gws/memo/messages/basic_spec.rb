require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: user, site: site) }

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
      expect(page).to have_content('宛先')
    end

    it '#edit' do
      visit edit_gws_memo_message_path(site: site, folder: 'INBOX.Draft', id: draft_memo.id)
      wait_for_ajax
      expect(page).to have_content('宛先')
    end

    it '#trash' do
      visit trash_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content('ゴミ箱')
    end

    # it '#toggle_star' do
    #   visit toggle_star_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
    #   expect(page).to have_content(memo.name)
    # end

    it '#trash_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.trash-all').click
      end
      wait_for_ajax
      expect(page).to have_content('ゴミ箱')
    end

    it '#set_seen_all and #unset_seen_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button "その他"
        find('.set-seen-all').click
      end
      wait_for_ajax
      expect(page).to have_css(".list-item.seen")
      expect(page).to have_no_css(".list-item.unseen")

      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button "その他"
        find('.unset-seen-all').click
      end
      wait_for_ajax
      expect(page).to have_css(".list-item.unseen")
      expect(page).to have_no_css(".list-item.seen")
    end

    it '#set_star_all and #unset_star_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      click_button "その他"
      wait_for_ajax
      page.accept_confirm do
        click_link 'スターをつける'
      end
      wait_for_ajax
      expect(page).to have_css(".icon.icon-star.on")
      expect(page).to have_no_css(".icon.icon-star.off")

      find('.list-head label.check input').set(true)
      click_button "その他"
      wait_for_ajax
      page.accept_confirm do
        click_link 'スターをはずす'
      end
      wait_for_ajax
      expect(page).to have_css(".icon.icon-star.off")
      expect(page).to have_no_css(".icon.icon-star.on")
    end

    it '#move_all' do
      visit gws_memo_messages_path(site)
      wait_for_ajax
      expect(page).to have_content('受信トレイ')
      expect(page).to have_content('ゴミ箱')
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button "移動する"
        find('.move-menu li a').click
      end
      wait_for_ajax
      expect(page).to have_content('受信トレイ')
      expect(page).to have_content('ゴミ箱')
    end
  end
end
