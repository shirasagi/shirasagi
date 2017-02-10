Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code loading.
  config.cache_classes = true
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Don't include all helpers
  config.action_controller.include_all_helpers = false

  # Configure static asset server for tests with Cache-Control for performance.
  #config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # ActiveJob Queue Adapter
  config.active_job.queue_adapter = :test

  # Cache
  config.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
  config.assets.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
  config.assets.configure do |env|
    env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
  end
end
