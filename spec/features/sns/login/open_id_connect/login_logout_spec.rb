require 'spec_helper'

describe "sns/login/saml", type: :feature, dbscope: :example, js: true do
  let!(:auth) do
    Sys::Auth::OpenIdConnect.create(
      name: unique_id, filename: unique_id, text: sys_user.email,
      client_id: unique_id, in_client_secret: unique_id,
      issuer: "http://#{unique_id}.example.jp", response_type: response_type
    )
  end

  context "with implicit flow" do
    let(:response_type) { "id_token" }

    before do
      server = Capybara.current_session.server
      host = "#{server.host}:#{server.port}"

      auth.auth_url = sns_login_open_id_connect_implicit_url(protocol: "http", host: host, id: auth.filename)
      auth.save!
    end

    it do
      visit sns_mypage_path
      click_on auth.name

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: sys_user.name)
      expect(page).to have_css(".main-navi", text: I18n.t("sns.account"))
    end
  end

  context "with authorization code flow" do
    let(:response_type) { "code" }

    before do
      server = Capybara.current_session.server
      host = "#{server.host}:#{server.port}"

      auth.auth_url = sns_login_open_id_connect_authorization_code_url(protocol: "http", host: host, id: auth.filename)
      auth.token_url = sns_login_open_id_connect_authorization_token_url(protocol: "http", host: host, id: auth.filename)
      auth.save!
    end

    it do
      visit sns_mypage_path
      click_on auth.name

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: sys_user.name)
      # confirm sns_mypage is shown to user
      expect(page).to have_css(".main-navi", text: I18n.t("sns.account"))
    end
  end

  context "when user directly log in to gws with implicit flow" do
    let(:response_type) { "id_token" }
    let(:organization) { gws_site }

    before do
      server = Capybara.current_session.server
      host = "#{server.host}:#{server.port}"

      auth.auth_url = sns_login_open_id_connect_implicit_url(protocol: "http", host: host, id: auth.filename)
      auth.save!
    end

    it do
      visit gws_portal_path(site: organization)
      expect(page).to have_css("#page-login")
      click_on auth.name

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .name", text: sys_user.name)
      # confirm gws_portal is shown to user
      expect(page).to have_css("#head .application-menu .gws .current", text: I18n.t('ss.links.gws'))
    end
  end
end
