require "active_support/core_ext/integer/time"
require_relative "../../lib/active_job/queue_adapters/shirasagi_adapter"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Don't include all helpers
  # include_all_helpers が true の場合、"Cms::ListHelper#render_page_list" ではなく
  # "Opendata::ListHelper#render_page_list" が実行され、view のレンダリングに失敗する。
  config.action_controller.include_all_helpers = false

  # CSRF
  config.action_controller.per_form_csrf_tokens = false
  config.action_controller.forgery_protection_origin_check = false

  # action view
  config.action_view.automatically_disable_submit_tag = true
  config.action_view.form_with_generates_remote_forms = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # config.cache_store = :memory_store
    config.cache_store = :file_store, "#{Rails.root}/tmp/cache_store"
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  config.action_mailer.delivery_method = :file

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # ActiveJob Queue Adapter
  config.active_job.queue_adapter = :shirasagi

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Compress using a preprocessor.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # other assets configurations
  config.assets.compress = true
  config.assets.prefix = "/assets-dev"
  config.sass.debug_info = false
  config.sass.inline_source_maps = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = false

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Logger
  # config.logger = ActiveSupport::Logger.new("#{Rails.root}/log/development.log")
  config.log_formatter = Logger::Formatter.new
  config.log_level = ENV['DEVELOPMENT_LOG_LEVEL'] || :debug
end
