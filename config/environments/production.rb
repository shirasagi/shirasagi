require "active_support/core_ext/integer/time"
require_relative "../../lib/active_job/queue_adapters/shirasagi_adapter"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

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

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false
  config.assets.compile = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # other asset pipeline configurations.
  config.assets.compress = true
  config.assets.digest = false
  config.assets.version = '1.0'
  config.sass.debug_info = false # for cms
  config.sass.line_numbers = false

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT by default
  # config.logger = ActiveSupport::Logger.new(STDOUT)
  config.logger = ActiveSupport::Logger.new("#{Rails.root}/log/production.log")

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  # config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_level = :warn

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store
  config.cache_store = :file_store, "#{Rails.root}/private/cache_store"

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  config.active_job.queue_adapter = :shirasagi
  # config.active_job.queue_name_prefix = "ss_production"

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [ :en ]

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
