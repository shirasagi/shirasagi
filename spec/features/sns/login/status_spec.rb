require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example, js: true do
  let(:user) { sys_user }

  it do
    visit sns_login_path
    within "form" do
      fill_in "item[email]", with: user.email
      fill_in "item[password]", with: user.in_password.presence || "pass"
      click_on I18n.t("ss.login")
    end
    expect(page).to have_css(".user .user-name", text: user.name)
    expect(page.evaluate_script("document.body.hasAttribute('data-ss-session')")).to be_falsey

    # disable redirecting to login
    page.execute_script("SS_Login.loginPath = null;")

    wait_for_event_fired("ss:sessionAlive") do
      page.execute_script("SS_Login.loggedinCheck();")
    end
    expect(page.evaluate_script("document.body.getAttribute('data-ss-session')")).to eq "alive"

    # 1.second 加えれば十分なはずだが、CIでテストが失敗するため、1.minute を加える
    Timecop.travel(Time.zone.now + SS.session_lifetime_of_user(user).seconds + 1.minute) do
      page.accept_alert(I18n.t("ss.warning.session_timeout", locale: user.lang)) do
        page.execute_script("SS_Login.loggedinCheck();")
      end
      expect(page.evaluate_script("document.body.getAttribute('data-ss-session')")).to eq "expired"
    end
  end
end
