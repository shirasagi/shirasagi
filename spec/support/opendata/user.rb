def opendata_member(site, oauth_type, oauth_id)
  opendata_member ||= create(:opendata_member, site: site, oauth_type: oauth_type, oauth_id: oauth_id, oauth_token: "token")
  opendata_member
end

def set_omniauth(service)
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[service] = OmniAuth::AuthHash.new(
    {
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
  visit "http://#{site.domain}#{provide_path}"
end
