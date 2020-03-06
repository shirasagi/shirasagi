require 'spec_helper'

describe 'gws_memo_notice_user_settings', type: :feature, dbscope: :example do
  context "basic crud" do
    let!(:site) { gws_site }
    let!(:show_path) { gws_memo_notice_user_settings_path site }
    let!(:edit_path) { edit_gws_memo_notice_user_settings_path site }

    before { login_gws_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in "item[send_notice_mail_addresses]", with: gws_user.email
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).to eq show_path
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_content(gws_user.email)
    end
  end
end
