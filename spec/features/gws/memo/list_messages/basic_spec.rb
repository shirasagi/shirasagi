require 'spec_helper'

describe 'gws_memo_list_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:list) { create(:gws_memo_list, cur_site: site) }
  let(:subject1) { "subject-#{unique_id}" }
  let(:subject2) { "subject-#{unique_id}" }
  let(:text1) { "text-#{unique_id}\r\ntext-#{unique_id}\r\ntext-#{unique_id}" }
  let(:text2) { "text-#{unique_id}\r\ntext-#{unique_id}\r\ntext-#{unique_id}" }

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
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject1
        fill_in 'item[text]', with: text1

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # update
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject1
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        fill_in 'item[subject]', with: subject2
        fill_in 'item[text]', with: text2

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # send
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject2
      click_on I18n.t('gws/memo.links.publish')
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.send')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

      # delete
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject2
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
