require 'spec_helper'

describe "cms_users", type: :feature, dbscope: :example do
  let(:site) { cms_site }

  shared_examples "shows cms error page" do
    it do
      expect(page).to have_title(title)
      within "#head" do
        expect(page).to have_css(".ss-logo-application-name", text: "SHIRASAGI")
        expect(page).to have_css("nav.user")
      end
      within ".site-navi" do
        expect(page).to have_link(I18n.t("cms.view_site"))
        expect(page).to have_link(I18n.t("cms.preview_site"))
      end
      within first(".main-navi") do
        expect(page).to have_link(I18n.t("cms.content"), href: cms_contents_path(site: site))
        expect(page).to have_link(I18n.t("cms.node"))
      end
      within "#crumbs" do
        expect(page).to have_link(site.name, href: cms_contents_path(site: site))
      end
      within "#addon-basic" do
        expect(page).to have_css(".addon-head", text: I18n.t("ss.rescues.default.head"))
        expect(page).to have_css(".addon-body", text: I18n.t("ss.rescues.default.body").split("<br>").first)
      end
      within "footer.send" do
        expect(page).to have_link(I18n.t("ss.links.back"), href: cms_main_path(site: site))
      end
    end
  end

  context "403: when user has no permissions" do
    let(:group) { cms_group }
    let(:user) { create :cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ] }
    let(:title) { "403 Forbidden | SHIRASAGI" }

    before do
      login_user user
      visit cms_users_path(site: site)
    end

    include_context "shows cms error page"
  end

  context "404: when no records are existed" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_cms_user
      visit cms_user_path(site: site, id: 999_999)
    end

    include_context "shows cms error page"
  end

  context "404: when no route matches" do
    let(:title) { "404 Not Found | SHIRASAGI" }

    before do
      login_cms_user
      visit "#{cms_main_path(site: site)}/#{unique_id}"
    end

    include_context "shows cms error page"
  end

  context "404: when no sites are existed" do
    before do
      login_cms_user
      visit cms_main_path(site: 999_999)
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
