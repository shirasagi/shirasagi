require 'spec_helper'

describe "webmail_account_settings", type: :feature, dbscope: :example do
  let(:show_path) { webmail_account_setting_path }

  context "with auth", js: true do
    before { login_ss_user }

    it "#show" do
      visit show_path
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.edit')
      click_button I18n.t('webmail.buttons.test_connection')
      click_button I18n.t('ss.buttons.save')

      expect(current_path).to eq show_path
    end
  end
end
