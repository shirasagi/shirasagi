require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true
  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Don't include all helpers
  config.action_controller.include_all_helpers = false

  # CSRF
  config.action_controller.per_form_csrf_tokens = false
  config.action_controller.forgery_protection_origin_check = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # action view
  config.action_view.automatically_disable_submit_tag = true
  config.action_view.form_with_generates_remote_forms = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :file_store, "#{Rails.root}/tmp/rspec_#{$PID}/cache_store"

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Compress using a preprocessor.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Logger
  config.log_formatter = ::Logger::Formatter.new
  config.log_level = ENV['TEST_LOG_LEVEL'] || :debug

  # ActiveJob Queue Adapter
  config.active_job.queue_adapter = :test

  config.assets.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
  config.assets.configure do |env|
    env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
  end
end
