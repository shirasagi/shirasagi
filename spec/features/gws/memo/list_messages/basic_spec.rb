require 'spec_helper'

describe 'gws_memo_list_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:list) { create(:gws_memo_list, cur_site: site, sender_name: "sender-#{unique_id}") }
  let(:subject1) { "subject-#{unique_id}" }
  let(:subject2) { "subject-#{unique_id}" }
  let(:text1) { Array.new(3) { "text-#{unique_id}" } }
  let(:text2) { Array.new(3) { "text-#{unique_id}" } }

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
        fill_in 'item[subject]', with: subject1
        fill_in 'item[text]', with: text1.join("\n")

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Memo::ListMessage.all.and_list_message.count).to eq 1
      Gws::Memo::ListMessage.all.and_list_message.first.tap do |message|
        expect(message.list).to eq list
        expect(message.subject).to eq subject1
        expect(message.text).to eq text1.join("\r\n")
        expect(message.format).to eq "text"
        expect(message.state).to eq "closed"
        expect(message.size).to eq 1024
        expect(message.from_member_name).to eq list.sender_name
        expect(message.member_ids).to be_blank
        expect(message.to_member_ids).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        expect(message.user_settings).to be_blank
      end

      # update
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject1
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within 'form#item-form' do
        fill_in 'item[subject]', with: subject2
        fill_in 'item[text]', with: text2.join("\n")

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # send
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject2
      within ".nav-menu" do
        click_on I18n.t('gws/memo.links.publish')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.send')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

      expect(Gws::Memo::ListMessage.all.and_list_message.count).to eq 1
      Gws::Memo::ListMessage.all.and_list_message.first.tap do |message|
        expect(message.list).to eq list
        expect(message.subject).to eq subject2
        expect(message.text).to include(text2.join("\r\n"))
        expect(message.text).to include(list.signature)
        expect(message.format).to eq "text"
        expect(message.state).to eq "public"
        expect(message.size).to eq 1024
        expect(message.from_member_name).to eq list.sender_name
        expect(message.member_ids).to eq list.overall_members.pluck(:id)
        expect(message.to_member_ids).to be_blank
        expect(message.cc_member_ids).to be_blank
        expect(message.bcc_member_ids).to be_blank
        user_settings = list.overall_members.pluck(:id).map { |id| { "user_id" => id, "path" => "INBOX" } }
        expect(message.user_settings).to include(*user_settings)
      end

      # delete
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject2
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Memo::ListMessage.all.and_list_message.count).to eq 0
    end
  end
end
