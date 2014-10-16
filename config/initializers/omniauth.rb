Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Rails.application.secrets.twitter_consumer_key, Rails.application.secrets.twitter_consumer_secret
  provider :facebook, Rails.application.secrets.facebook_app_id, Rails.application.secrets.facebook_app_secret
  provider :yahoojp, Rails.application.secrets.yahoo_app_id, Rails.application.secrets.yahoo_secret, {:scope => "openid profile email address"}
  provider :google_oauth2, Rails.application.secrets.google_client_id, Rails.application.secrets.google_secret, {:scope => "userinfo.email, userinfo.profile, plus.me"}
  OmniAuth.config.on_failure = Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
end
