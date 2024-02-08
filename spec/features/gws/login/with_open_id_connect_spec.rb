require 'spec_helper'

describe "gws_login", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:auth) do
    Sys::Auth::OpenIdConnect.create(
      name: unique_id, filename: unique_id, text: user.email,
      client_id: unique_id, in_client_secret: unique_id,
      issuer: "http://#{unique_id}.example.jp", response_type: response_type
    )
  end

  context "with open id connect (implicit flow)" do
    let(:response_type) { "id_token" }

    before do
      server = Capybara.current_session.server
      host = "#{server.host}:#{server.port}"

      auth.auth_url = sns_login_open_id_connect_implicit_url(protocol: "http", host: host, id: auth.filename)
      auth.save!

      presence = user.user_presence(site)
      presence.sync_available_state = "enabled"
      presence.sync_unavailable_state = "enabled"
      presence.save!
    end

    it do
      visit gws_login_path(site: site)
      click_on auth.name

      # confirm a user has been logged-in
      expect(page).to have_css("nav.user .user-name", text: user.name)
      # confirm gws_portal is shown to user
      expect(page).to have_css("#head .application-menu .gws .current", text: I18n.t('ss.links.gws', locale: user.lang))

      presence = Gws::User.find(user.id).user_presence(site)
      expect(presence.state).to eq "available"

      # do logout
      within ".user-navigation" do
        wait_event_to_fire("turbo:frame-load") { click_on user.name }
        click_on I18n.t("ss.logout", locale: user.lang)
      end

      # confirm a login form has been shown
      expect(page).to have_css(".login-box", text: I18n.t("ss.login", locale: I18n.default_locale))
      expect(page).to have_css("li", text: auth.name)
      # and confirm browser back to gws_login
      expect(current_path).to eq gws_login_path(site: site)

      presence.reload
      expect(presence.state).to eq "unavailable"
    end
  end
end
