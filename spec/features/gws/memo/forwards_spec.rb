require 'spec_helper'

describe 'gws_memo_forwards', type: :feature, dbscope: :example do
  context "forward setting", js: true do
    let!(:site) { gws_site }
    let!(:show_path) { gws_memo_forwards_path site }

    before { login_gws_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.edit')

      # edit
      email = "sample@example.jp"
      within "form#item-form" do
        fill_in "item[email]", with: email
        click_button "保存"
      end

      expect(first('#addon-basic')).to have_text(email)
    end
  end
end
