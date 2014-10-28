Rails.application.config.middleware.use OmniAuth::Builder do
  secrets = Rails.application.secrets
  provider :twitter, secrets.twitter_key, secrets.twitter_secret
  provider :facebook, secrets.facebook_key, secrets.facebook_secret
  provider :yahoojp, secrets.yahoo_key, secrets.yahoo_secret, {scope: "openid profile email address"}
  provider :google_oauth2, secrets.google_key, secrets.google_secret, {scope: "userinfo.email, userinfo.profile, plus.me"}
  provider :github, secrets.github_key, secrets.github_secret
  OmniAuth.config.on_failure = Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
end
