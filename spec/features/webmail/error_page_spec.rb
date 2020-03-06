require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  shared_examples "shows webmail error page" do
    it do
      expect(page).to have_title(title)
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
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: webmail_main_path)
      end
    end
  end

  context "403: when user has no permissions" do
    let(:user) { create :webmail_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:title) { "403 Forbidden | SHIRASAGI" }

    before do
      login_user user
      visit webmail_users_path
    end

    include_context "shows webmail error page"
  end

  context "404: when no records are existed" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_webmail_user
      visit webmail_user_path(id: 999_999)
    end

    include_context "shows webmail error page"
  end

  context "404: when no routes matches" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_webmail_user
      visit "#{webmail_main_path}/#{unique_id}"
    end

    include_context "shows webmail error page"
  end
end
