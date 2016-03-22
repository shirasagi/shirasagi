# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_ss_session'
Rails.application.config.session_store :mongoid_store
Rails.application.config.session_options = { cookie_only: false, key: '_ss_session' }

if defined?(MongoidStore::Session)
  class MongoidStore::Session
    # set TTL index
    index({ updated_at: 1 }, { expire_after_seconds: 1.hour })
  end
end
