require 'spec_helper'

describe 'gws_memo_list_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:list) { create(:gws_memo_list, cur_site: site, sender_name: "sender-#{unique_id}", member_ids: [user.id]) }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { Array.new(3) { "text-#{unique_id}" } }

  context 'without login' do
    it do
      visit gws_memo_lists_path(site: site)
      expect(current_path).to eq sns_login_path
    end
  end

  context 'basic crud' do
    before { login_gws_user }

    it do
      # create
      visit gws_memo_list_messages_path(site: site, list_id: list)
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: text.join("\n")

        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # send
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject
      within ".nav-menu" do
        click_on I18n.t('gws/memo.links.publish')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.send')
      end
      wait_for_notice I18n.t('ss.notice.sent')

      expect(Gws::Memo::Message.all.count).to eq 1
      message = Gws::Memo::Message.first
      expect(message.user_id).to eq user.id

      # show
      visit gws_memo_messages_path(site: site)
      within ".list-items" do
        expect(page).to have_link(subject)
        click_on subject
      end

      # reply
      click_on I18n.t('ss.links.reply')
      within ".gws-addon-memo-member .to .ajax-selected" do
        expect(page).to have_selector("tr[data-id]", count: 1)
        expect(page).to have_text user.long_name
      end
      click_on I18n.t('ss.links.back_to_show')

      # reply_all
      click_on I18n.t('gws/memo/message.links.reply_all')
      within ".gws-addon-memo-member .to .ajax-selected" do
        expect(page).to have_selector("tr[data-id]", count: 0)
      end
    end
  end
end
