require 'spec_helper'

describe "sns/login/saml", type: :feature, dbscope: :example, js: true do
  let!(:auth) do
    Sys::Auth::OpenIdConnect.create(
      name: unique_id, filename: unique_id, text: sys_user.email,
      client_id: unique_id, in_client_secret: unique_id,
      issuer: "http://#{unique_id}.example.jp", response_type: response_type
    )
  end

  before do
    server = Capybara.current_session.server
    host_with_port = "#{server.host}:#{server.port}"

    auth.auth_url = sns_login_open_id_connect_auth_url(protocol: "http", host: host_with_port, id: auth.filename)
    auth.save!
  end

  context "with implicit flow" do
    let(:response_type) { "id_token" }

    it do
      visit sns_mypage_path
      click_on auth.name

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: sys_user.name)
      expect(page).to have_css(".main-navi", text: I18n.t("sns.account"))
    end
  end
end
