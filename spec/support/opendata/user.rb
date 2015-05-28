def opendata_member(site: cms_site, oauth_type: :twitter, oauth_id: "1234")
  email = "admin@example.jp"
  opendata_member = Opendata::Member.where(email: email).first
  opendata_member ||= create(:opendata_member, site: site, email: email, oauth_type: oauth_type, oauth_id: oauth_id, oauth_token: "token")
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

def login_opendata_member(site, node, member = opendata_member(site: site))
  oauth_user = set_omniauth(member)
  provide_path = "#{node.url}#{oauth_user.provider}"
  visit "http://#{site.domain}#{provide_path}"
end
