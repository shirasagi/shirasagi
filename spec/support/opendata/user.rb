def opendata_member(site, oauth_type, oauth_id)
  opendata_member ||= create(:opendata_member, site: site, oauth_type: oauth_type, oauth_id: oauth_id)
  opendata_member
end

def set_omniauth(site, service)
  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[service] = OmniAuth::AuthHash.new({
    oauth_type: service.to_s,
    oauth_id: '1234'
  })

  case service
    when :twitter
      OmniAuth.config.add_mock(service,
        { info: {
            nickname: "#{service.to_s}_oauth_user"
          }
        }
      )
    end

  opendata_member(site, service.to_s, '1234')
  OmniAuth.config.mock_auth[service]
end

def login_opendata_member(site, node)
  oauth_user = set_omniauth(site, :twitter)
  provide_path = "#{node.url}#{oauth_user.provider}"
  page.driver.browser.with_session("public") do |session|
    session.env("HTTP_X_FORWARDED_HOST", site.domain)
    session.env("REQUEST_PATH", provide_path)
    visit provide_path
  end
end