require 'spec_helper'

describe "sys_notice", type: :feature, dbscope: :example do
  let!(:current) { Time.zone.now.beginning_of_minute }
  let!(:release_date) { current + 1.day }
  let!(:close_date) { release_date + 1.day }
  let!(:notice0) do
    create(
      :sys_notice, state: "public", notice_severity: "high", notice_target: Sys::Notice::NOTICE_TARGETS,
      release_date: release_date, close_date: close_date
    )
  end
  let!(:notice1) do
    create(
      :sys_notice, state: "public", notice_severity: "normal", notice_target: Sys::Notice::NOTICE_TARGETS,
      release_date: release_date, close_date: close_date
    )
  end

  before do
    cms_site
    gws_site

    sys_user
    cms_user
    gws_user
  end

  context "just before release date" do
    it do
      Timecop.freeze(release_date - 1.second) do
        visit sns_login_path
        expect(page).to have_no_css(".login-notice")

        login_sys_user
        visit sns_mypage_path
        expect(page).to have_no_css(".notices")

        login_cms_user
        visit cms_contents_path(site: cms_site)
        expect(page).to have_no_css(".notices")

        login_gws_user
        visit gws_portal_path(site: gws_site)
        expect(page).to have_no_css(".sys-notices")
      end
    end
  end

  context "at release date" do
    it do
      Timecop.freeze(release_date) do
        visit sns_login_path
        within ".login-notice" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_sys_user
        visit sns_mypage_path
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_cms_user
        visit cms_contents_path(site: cms_site)
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_gws_user
        visit gws_portal_path(site: gws_site)
        within ".sys-notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end
      end
    end
  end

  context "just before close date" do
    it do
      Timecop.freeze(close_date - 1.second) do
        visit sns_login_path
        within ".login-notice" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_sys_user
        visit sns_mypage_path
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_cms_user
        visit cms_contents_path(site: cms_site)
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end

        login_gws_user
        visit gws_portal_path(site: gws_site)
        within ".sys-notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end
      end
    end
  end

  context "at close date" do
    it do
      Timecop.freeze(close_date) do
        visit sns_login_path
        expect(page).to have_no_css(".login-notice")

        login_sys_user
        visit sns_mypage_path
        expect(page).to have_no_css(".notices")

        login_cms_user
        visit cms_contents_path(site: cms_site)
        expect(page).to have_no_css(".notices")

        login_gws_user
        visit gws_portal_path(site: gws_site)
        expect(page).to have_no_css(".sys-notices")
      end
    end
  end
end
