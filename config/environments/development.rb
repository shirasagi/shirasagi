Rails.application.configure do

  # Code loading.
  config.cache_classes = false
  config.eager_load = false

  # Don't include all helpers
  config.action_controller.include_all_helpers = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Asset pipeline.
  config.serve_static_assets = true
  config.assets.debug = true
  #config.assets.raise_runtime_errors = true
  config.assets.compress = false
  config.sass.debug_info = true
  config.assets.prefix = "/assets-dev"

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Logger
  config.logger = Logger.new("#{Rails.root}/log/development.log")
  config.log_level = :warn
  # config.log_level = :debug
end
