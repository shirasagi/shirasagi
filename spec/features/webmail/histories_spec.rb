require 'spec_helper'

describe "webmail_histories", type: :feature, dbscope: :example do
  context "basic crud" do
    before { login_webmail_admin }

    it do
      #
      # Read
      #
      visit webmail_histories_path
      expect(page).to have_content(webmail_admin.name)

      click_on webmail_admin.name
      expect(page).to have_content(webmail_admin.name)

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
