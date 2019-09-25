require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  context "403: when user has no permissions" do
    let(:user) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }

    before { login_user user }

    it do
      visit webmail_users_path

      expect(page).to have_title("403 Forbidden | SHIRASAGI")
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".webmail-navi" do
        expect(page).to have_link(I18n.t("webmail.box.inbox"))
      end
      within first(".mod-navi") do
        expect(page).to have_link(I18n.t("webmail.mailbox"))
        expect(page).to have_link(I18n.t("webmail.signature"))
      end
      expect(page).to have_no_css("#crumbs")
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: webmail_main_path)
      end
    end
  end

  context "404: when no records are existed" do
    before { login_webmail_user }

    it do
      visit webmail_user_path(id: 999_999)

      expect(page).to have_title("404 Not Found | SHIRASAGI")
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".webmail-navi" do
        expect(page).to have_link(I18n.t("webmail.box.inbox"))
      end
      within first(".mod-navi") do
        expect(page).to have_link(I18n.t("webmail.mailbox"))
        expect(page).to have_link(I18n.t("webmail.signature"))
      end
      expect(page).to have_no_css("#crumbs")
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: webmail_main_path)
      end
    end
  end
end
