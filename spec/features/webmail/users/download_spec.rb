require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  let!(:user1) { create(:webmail_user, id: 101, email: "#{unique_id}-1@example.jp") }

  before { login_webmail_admin }

  context "download" do
    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.download")

      csv = CSV.parse(page.html.encode("UTF-8"), headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers).to have(Webmail::UserExport::EXPORT_DEF.length).items
    end
  end
end
