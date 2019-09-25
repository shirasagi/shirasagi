require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example do
  context "403: when user has no permissions" do
    let(:user) { create :ss_user, name: unique_id, email: "#{unique_id}@example.jp" }

    before { login_user user }

    it do
      visit sys_users_path

      expect(page).to have_title("403 Forbidden | SHIRASAGI")
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".main-navi" do
        expect(page).to have_link(I18n.t("sns.account"))
        expect(page).to have_link(I18n.t("job.task_manager"))
      end
      expect(page).to have_no_css("#crumbs")
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: sns_mypage_path)
      end
    end
  end

  context "404: when no records are existed" do
    before { login_sys_user }

    it do
      visit sys_user_path(id: 999_999)

      expect(page).to have_title("404 Not Found | SHIRASAGI")
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".main-navi" do
        expect(page).to have_link(I18n.t("sns.account"))
        expect(page).to have_link(I18n.t("job.task_manager"))
      end
      expect(page).to have_no_css("#crumbs")
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: sns_mypage_path)
      end
    end
  end
end
