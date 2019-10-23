require 'spec_helper'

describe "sys_notice", type: :feature, dbscope: :example do
  let!(:notice0) do
    create(:sys_notice, notice_severity: "high", notice_target: %w(login_view cms_admin gw_admin webmail_admin sys_admin))
  end
  let!(:notice1) { create(:sys_notice, notice_severity: "high", notice_target: %w(login_view)) }
  let!(:notice2) { create(:sys_notice, notice_severity: "high", notice_target: %w(cms_admin)) }
  let!(:notice3) { create(:sys_notice, notice_severity: "high", notice_target: %w(gw_admin)) }
  let!(:notice4) { create(:sys_notice, notice_severity: "high", notice_target: %w(webmail_admin)) }
  let!(:notice5) { create(:sys_notice, notice_severity: "high", notice_target: %w(sys_admin)) }

  context "login" do
    it do
      visit sns_login_path

      within ".login-notice" do
        expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
        expect(page).to have_css(".list-item .notice-severity-high", text: notice1.name)
        expect(page).to have_no_css(".list-item", text: notice2.name)
        expect(page).to have_no_css(".list-item", text: notice3.name)
        expect(page).to have_no_css(".list-item", text: notice4.name)
        expect(page).to have_no_css(".list-item", text: notice5.name)

        click_on notice0.name
      end
      within ".main-box" do
        expect(page).to have_content(ApplicationController.helpers.sanitize(notice0.html, tags: []))
      end
    end
  end

  context "sys" do
    before { login_sys_user }

    it do
      visit sns_mypage_path

      within ".notices" do
        expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
        expect(page).to have_no_css(".list-item", text: notice1.name)
        expect(page).to have_no_css(".list-item", text: notice2.name)
        expect(page).to have_no_css(".list-item", text: notice3.name)
        expect(page).to have_no_css(".list-item", text: notice4.name)
        expect(page).to have_css(".list-item .notice-severity-high", text: notice5.name)

        click_on notice0.name
      end
      within ".main-box" do
        expect(page).to have_content(ApplicationController.helpers.sanitize(notice0.html, tags: []))
      end
    end
  end

  context "cms" do
    let!(:site) { cms_site }

    before { login_cms_user }

    it do
      visit cms_contents_path(site: site)

      within ".notices" do
        expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
        expect(page).to have_no_css(".list-item", text: notice1.name)
        expect(page).to have_css(".list-item .notice-severity-high", text: notice2.name)
        expect(page).to have_no_css(".list-item", text: notice3.name)
        expect(page).to have_no_css(".list-item", text: notice4.name)
        expect(page).to have_no_css(".list-item", text: notice5.name)

        click_on notice0.name
      end
      within ".main-box" do
        expect(page).to have_content(ApplicationController.helpers.sanitize(notice0.html, tags: []))
      end
    end
  end

  context "gws" do
    let!(:site) { gws_site }

    before { login_gws_user }

    it do
      visit gws_portal_path(site: site)

      within ".index" do
        expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
        expect(page).to have_no_css(".list-item", text: notice1.name)
        expect(page).to have_no_css(".list-item", text: notice2.name)
        expect(page).to have_css(".list-item .notice-severity-high", text: notice3.name)
        expect(page).to have_no_css(".list-item", text: notice4.name)
        expect(page).to have_no_css(".list-item", text: notice5.name)

        click_on notice0.name
      end
      within ".main-box" do
        expect(page).to have_content(ApplicationController.helpers.sanitize(notice0.html, tags: []))
      end
    end
  end

  context "webmail", imap: true do
    let(:user) { webmail_imap }

    before { login_user(user) }

    it do
      visit webmail_mails_path(account: 0)

      within ".notices" do
        expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
        expect(page).to have_no_css(".list-item", text: notice1.name)
        expect(page).to have_no_css(".list-item", text: notice2.name)
        expect(page).to have_no_css(".list-item", text: notice3.name)
        expect(page).to have_css(".list-item .notice-severity-high", text: notice4.name)
        expect(page).to have_no_css(".list-item", text: notice5.name)

        click_on notice0.name
      end
      within ".main-box" do
        expect(page).to have_content(ApplicationController.helpers.sanitize(notice0.html, tags: []))
      end
    end
  end
end
