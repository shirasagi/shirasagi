require 'spec_helper'

describe "sys_notice", type: :feature, dbscope: :example, js: true do
  let(:heading) { "heading-#{unique_id}" }
  let(:html0) { "<p><h2 class=\"heading\">#{heading}</h2></p>" }
  let!(:notice0) do
    create(
      :sys_notice, state: "public", notice_severity: "high", notice_target: Sys::Notice::NOTICE_TARGETS, html: html0
    )
  end
  let(:html) { "<p><a class=\"link\" href=\"#{sns_public_notice_path(id: notice0)}\">#{notice0.name}</a></p>" }
  let!(:notice) do
    create(
      :sys_notice, state: "public", notice_severity: "high", notice_target: Sys::Notice::NOTICE_TARGETS, html: html
    )
  end

  # before do
  #   cms_site
  #   gws_site
  #
  #   sys_user
  #   cms_user
  #   gws_user
  # end

  context "when <a> is clicked" do
    context "on login" do
      it do
        visit sns_login_path
        click_on notice.name

        within ".ss-notice-wrap" do
          click_on notice0.name
        end

        expect(page).to have_css(".heading", text: heading)
      end
    end

    context "on sys" do
      before do
        sys_user
        login_sys_user
      end

      it do
        visit sns_mypage_path
        click_on notice.name

        within ".ss-notice-wrap" do
          click_on notice0.name
        end

        expect(page).to have_css(".heading", text: heading)
      end
    end

    context "on cms" do
      before do
        cms_site
        cms_user

        login_cms_user
      end

      it do
        visit cms_contents_path(site: cms_site)
        click_on notice.name

        within ".ss-notice-wrap" do
          click_on notice0.name
        end

        expect(page).to have_css(".heading", text: heading)
      end
    end

    context "on gws" do
      before do
        gws_site
        gws_user

        login_gws_user
      end

      it do
        visit gws_portal_path(site: gws_site)
        click_on notice.name

        within ".ss-notice-wrap" do
          click_on notice0.name
        end

        expect(page).to have_css(".heading", text: heading)
      end
    end
  end
end
