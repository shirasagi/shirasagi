require 'spec_helper'

describe 'gws_memo_message_export_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: user, site: site) }

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit gws_memo_export_messages_path(site)
      expect(page).to have_content(I18n.t('ss.links.export'))
    end

    it '#export json' do
      visit gws_memo_export_messages_path(site)
      select 'json', from: 'item_format'
      click_link I18n.t('ss.links.select')
      click_link memo.subject
      click_button I18n.t('ss.links.export')
      expect(current_path).not_to eq gws_memo_export_messages_path(site)
      expect(current_path).to eq gws_memo_start_export_messages_path(site)

      within "#addon-basic" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end
    end

    it '#export eml' do
      visit gws_memo_export_messages_path(site)
      select 'eml', from: 'item_format'
      click_link I18n.t('ss.links.select')
      click_link memo.subject
      click_button I18n.t('ss.links.export')
      expect(current_path).not_to eq gws_memo_export_messages_path(site)
      expect(current_path).to eq gws_memo_start_export_messages_path(site)

      within "#addon-basic" do
        expect(page).to have_content(I18n.t("gws/memo/message.export.start_message").split("\n").first)
      end

      expect(Gws::Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end
    end
  end
end
