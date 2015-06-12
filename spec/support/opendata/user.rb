def opendata_member(site: cms_site, oauth_type: :twitter, oauth_id: "1234")
  email = "admin@example.jp"
  opendata_member = Opendata::Member.where(email: email).first
  opendata_member ||= create(:opendata_member,
                             site: site,
                             email: email,
                             oauth_type: oauth_type,
                             oauth_id: oauth_id,
                             oauth_token: "token")
  opendata_member
end

def set_omniauth(member = opendata_member)
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[member.oauth_type.to_sym] = OmniAuth::AuthHash.new(
    {
      provider: member.oauth_type.to_s,
      uid: member.oauth_id,
      credentials: {
        token: member.oauth_token
      },
      info: {
        name: member.name
      }
    })
  OmniAuth.config.mock_auth[member.oauth_type.to_sym]
end

def fail_omniauth(service)
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[service] = :invalid_credentials
  OmniAuth.config.mock_auth[service]
end

def create_auth_hash(member)
  hash = { provider: member.oauth_type,
           uid: member.oauth_id,
           credentials: { token: member.oauth_token },
           info: { name: member.name } }
  OmniAuth::AuthHash.new(hash)
end

def login_opendata_member(site, node, member = opendata_member(site: site))
  login_url = "http://#{site.domain}#{node.url}login.html"

  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[member.oauth_type.to_sym] = create_auth_hash(member)

  visit login_url
  click_link "Twitter ID でログイン"
end

def logout_opendata_member(site, node, member = opendata_member(site: site))
  logout_url = "http://#{site.domain}#{node.url}logout.html"
  visit logout_url

  OmniAuth.config.test_mode = false
  OmniAuth.config.mock_auth[member.oauth_type.to_sym] = :invalid_credentials
end
