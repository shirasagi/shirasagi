require 'spec_helper'

describe "webmail_groups", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "download" do
    it do
      visit webmail_groups_path
      click_on I18n.t("ss.links.download")

      csv = CSV.parse(page.html.encode("UTF-8"), headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers).to have(Webmail::GroupExport::EXPORT_DEF.length).items
      expect(csv.headers.include?(Webmail::GroupExport::EXPORT_DEF.sample[:label])).to be_truthy
    end
  end
end
