require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example do
  shared_examples "shows sys/sns error page" do
    it do
      expect(page).to have_title(title)
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".main-navi" do
        expect(page).to have_link(I18n.t("sns.account"))
        expect(page).to have_link(I18n.t("job.task_manager"))
      end
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: sns_mypage_path)
      end
    end
  end

  context "403: when user has no permissions" do
    let(:user) { create :ss_user, name: unique_id, email: "#{unique_id}@example.jp" }
    let(:title) { "403 Forbidden | SHIRASAGI" }

    before do
      login_user user
      visit sys_users_path
    end

    include_context "shows sys/sns error page"
  end

  context "404: when no records are existed" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_sys_user
      visit sys_user_path(id: 999_999)
    end

    include_context "shows sys/sns error page"
  end

  context "404: when no routes matches" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_sys_user
      visit "#{sys_main_path}/#{unique_id}"
    end

    include_context "shows sys/sns error page"
  end
end
