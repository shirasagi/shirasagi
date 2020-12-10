# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_ss_session'
Rails.application.config.session_store :mongoid_store
Rails.application.config.session_options = begin
  options = { cookie_only: false }
  options[:key] = SS.config.ss.session["key"].presence || '_ss_session'
  options[:same_site] = SS.config.ss.session["same_site"] if !SS.config.ss.session["same_site"].nil?
  options[:secure] = SS.config.ss.session["secure"] if !SS.config.ss.session["secure"].nil?
  options
end

if defined?(MongoidStore::Session)
  class MongoidStore::Session
    # set TTL index
    index({ updated_at: 1 }, { expire_after_seconds: 1.hour })

    if Mongoid::Config.clients[:default_post]
      store_in client: :default_post
    end
  end
end
