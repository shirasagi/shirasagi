# Action View Sanitize Helpers
# The default, starting in Rails 7.1, is to use an HTML5 parser for sanitization (if it is available, see NOTE below). If you wish to revert back to the previous HTML4 behavior, you can do so by setting the following in your application configuration:
Rails.application.config.action_view.sanitizer_vendor = Rails::HTML4::Sanitizer
