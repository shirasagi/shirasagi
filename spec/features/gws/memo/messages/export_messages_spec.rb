require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:memo) { create(:gws_memo_message, user: user, site: site) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, user: user, site: site) }

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit gws_memo_export_messages_path(site)
      expect(page).to have_content('エクスポート')
    end

    it '#export' do
      visit gws_memo_export_messages_path(site)
      select 'eml', from: 'item_format'
      find('#item_message_ids_', visible: false).set(memo.id)
      click_button "エクスポート"
      expect(status_code).to eq 200
      expect(current_path).not_to eq gws_memo_export_messages_path(site)
      expect(current_path).to eq gws_memo_start_export_messages_path(site)
    end
  end
end
