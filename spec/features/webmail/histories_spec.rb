require 'spec_helper'

describe "webmail_histories", type: :feature, dbscope: :example do
  context "basic crud" do
    before { login_webmail_admin }

    it do
      #
      # Read
      #
      visit webmail_histories_path
      expect(page).to have_css(".list-item", text: webmail_admin.name)

      within ".list-items" do
        click_on webmail_admin.name
      end
      expect(page).to have_css("#addon-basic", text: webmail_admin.name)

      #
      # Download
      #
      visit webmail_histories_path
      click_on I18n.t("ss.links.download")
      within "form" do
        click_on I18n.t("ss.buttons.download")
      end
    end
  end
end
