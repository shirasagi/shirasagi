if SS.config.oauth.prefix_path
  OmniAuth.configure do |config|
    config.logger = Rails.logger
    config.path_prefix = SS.config.oauth.prefix_path
    config.on_failure = proc do |env|
      config.path_prefix = env["ss.node"].url
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    end
  end

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider ::OAuth::Twitter
    provider ::OAuth::Facebook
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
