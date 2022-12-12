require 'spec_helper'

describe "webmail_groups", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "download" do
    it do
      visit webmail_groups_path
      click_on I18n.t("ss.links.download")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv.force_encoding("UTF-8")
      csv = CSV.parse(csv, headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers.length).to be > 20
      expect(csv.headers).to include(Webmail::Group.t(:name))
      expect(csv.headers).to include("IMAP_" + Webmail::ImapSetting.t('name'))
    end
  end
end
