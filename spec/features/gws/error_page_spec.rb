require 'spec_helper'

describe "gws_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }

  shared_examples "shows gws error page" do
    it do
      expect(page).to have_title(title)
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".main-navi" do
        expect(page).to have_link(I18n.t('modules.gws/portal'), href: gws_portal_path(site: site))
      end
      within "#crumbs" do
        expect(page).to have_link(site.name, href: gws_portal_path(site: site))
      end
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: gws_portal_path(site: site))
      end
    end
  end

  context "403: when user has no permissions" do
    let(:role) { create :gws_role_portal_user_use }
    let(:user) { create :gws_user, name: unique_id, email: unique_email, group_ids: [ site.id ], gws_role_ids: [ role.id ] }
    let(:title) { "403 Forbidden | SHIRASAGI" }

    before do
      login_user user
      visit gws_groups_path(site: site)
    end

    include_context "shows gws error page"
  end

  context "404: when no records are existed" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_gws_user
      visit gws_user_path(site: site, id: 999_999)
    end

    include_context "shows gws error page"
  end

  context "404: when no routes matches" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_gws_user
      visit "#{gws_portal_path(site: site)}/#{unique_id}"
    end

    include_context "shows gws error page"
  end

  context "404: when no sites are existed" do
    before do
      login_gws_user
      visit gws_portal_path(site: 999_999)
    end

    it do
      # サイトが見つからない場合のエラー画面は sys のエラー画面と同じ
      expect(page).to have_title("404 Not Found | SHIRASAGI")
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
end
