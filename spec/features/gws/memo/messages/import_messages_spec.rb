require 'spec_helper'

describe "gws_memo_message_import_messages", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "import from zip" do
    before { login_gws_user }

    it do
      visit gws_memo_import_messages_path(site)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/memo/messages.zip"
        click_on I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("gws/memo/message.notice.start_import"))

      visit gws_memo_messages_path(site)
      expect(page).to have_css(".list-item.unseen", count: 7)
    end

    it 'import files which are right under root folder' do
      visit gws_memo_import_messages_path(site)

      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/memo/messages_under_root.zip"
        click_on I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("gws/memo/message.notice.start_import"))

      visit gws_memo_messages_path(site)

      expect(page).to have_text("no_name")
      expect(page).to have_text("(3)")
      expect(page).to have_css(".folder .unseen", count: 1)
    end
  end
end
