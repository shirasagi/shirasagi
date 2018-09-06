require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "download" do
    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.download")

      csv_lines = CSV.parse(page.html.encode("UTF-8"))
      expect(csv_lines.length).to be > 0
    end
  end
end
