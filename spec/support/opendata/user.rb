def opendata_member(site, oauth_type, oauth_id)
  opendata_member ||= create(:opendata_member, site: site, oauth_type: oauth_type, oauth_id: oauth_id, oauth_token: "token")
  opendata_member
end

def set_omniauth(service)
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[service] = OmniAuth::AuthHash.new({
    provider: service.to_s,
    uid: "1234",
    credentials: {
      token: "token"
    }
  })
  OmniAuth.config.mock_auth[service]
end

def login_opendata_member(site, node)
  opendata_member(site, :twitter, "1234")
  oauth_user = set_omniauth(:twitter)
  provide_path = "#{node.url}#{oauth_user.provider}"
  page.driver.browser.with_session("public") do |session|
    session.env("HTTP_X_FORWARDED_HOST", site.domain)
    session.env("REQUEST_PATH", provide_path)
    session.env("HTTP_USER_AGENT", "user_agent")
    visit "http://#{site.domain}#{provide_path}"
  end
end