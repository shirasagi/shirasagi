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
  config.assets.compress = true
  config.assets.debug = false
  config.assets.prefix = "/assets-dev"
  #config.assets.raise_runtime_errors = true
  config.sass.debug_info = false
  config.sass.inline_source_maps = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Logger
  config.logger = Logger.new("#{Rails.root}/log/development.log")
  config.log_level = ENV['DEVELOPMENT_LOG_LEVEL'] || :warn
  # config.log_level = :debug

  # ActiveJob Queue Adapter
  config.active_job.queue_adapter = :shirasagi
end
