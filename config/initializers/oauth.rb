if SS.config.oauth.prefix_path
  OmniAuth.configure do |config|
    config.logger = Rails.logger
    config.on_failure = proc { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
    config.path_prefix = SS.config.oauth.prefix_path
  end

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider ::Oauth::Twitter
    provider ::Oauth::Facebook
    provider ::Oauth::YahooJp, { scope: "openid profile email address" }
    provider ::Oauth::GoogleOauth2, { scope: "userinfo.email, userinfo.profile, plus.me" }
    provider ::Oauth::Github
  end
end
