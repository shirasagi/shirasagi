require 'spec_helper'

describe "webmail_groups", type: :feature, dbscope: :example, js: true do
  before { login_webmail_admin }
  let!(:group) { create :webmail_group }

  context "download" do
    it do
      visit webmail_groups_path
      click_on I18n.t("ss.links.download")
      wait_for_download("webmail_groups", extname: ".csv") do
        within "form#item-form" do
          click_on I18n.t("ss.buttons.download")
        end
      end

      csv = ::CSV.read(downloaded_path, headers: true, encoding: 'UTF8')
      expect(csv).to have_at_least(1).items
      expect(csv.headers.length).to be > 10
      expect(csv.headers).to include(Webmail::Group.t(:name))
      expect(csv.headers).to include("IMAP_" + Webmail::ImapSetting.t('name'))
    end
  end
end
