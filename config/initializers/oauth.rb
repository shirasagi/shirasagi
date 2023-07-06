if SS.config.oauth.prefix_path
  OmniAuth.configure do |config|
    config.logger = Rails.logger
    config.path_prefix = SS.config.oauth.prefix_path
    config.on_failure = proc do |env|
      new_path = env["omniauth.origin"].presence
      new_path ||= env["ss.node"].try(:full_url)
      new_path ||= "/"
      Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
    end
  end

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider ::OAuth::Twitter
    provider ::OAuth::Facebook, {
      site: "https://graph.facebook.com/v17.0",
      authorize_url: "https://www.facebook.com/v17.0/dialog/oauth",
      scope: "public_profile"
    }
    provider ::OAuth::YahooJp, {
      name: "yahoojp_v2",
      scope: "openid profile email address"
    }
    provider ::OAuth::YahooJp, {
      scope: "openid profile email address",
      client_options: {
        authorize_url: '/yconnect/v1/authorization',
        token_url: '/yconnect/v1/token'
      }
    }
    provider ::OAuth::GoogleOAuth2, { scope: "userinfo.email, userinfo.profile, plus.me" }
    provider ::OAuth::Github
    provider ::OAuth::Line
  end
end
