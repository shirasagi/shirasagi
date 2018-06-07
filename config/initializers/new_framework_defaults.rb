# enable eager loading in production
Rails.application.config.enable_dependency_loading = true

# Enable per-form CSRF tokens. Previous versions had false.
Rails.application.config.action_controller.per_form_csrf_tokens = false

# Enable origin-checking CSRF mitigation. Previous versions had false.
Rails.application.config.action_controller.forgery_protection_origin_check = false

# Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
# Previous versions had false.
ActiveSupport.to_time_preserves_timezone = false

# Require `belongs_to` associations by default. Previous versions had false.
#Rails.application.config.active_record.belongs_to_required_by_default = false

# Do not halt callback chains when a callback returns false. Previous versions had true.
# ActiveSupport.halt_callback_chains_on_return_false = true

# Make `form_with` generate non-remote forms.
Rails.application.config.action_view.form_with_generates_remote_forms = false

# Unknown asset fallback will return the path passed in when the given
# asset is not present in the asset pipeline.
# Rails.application.config.assets.unknown_asset_fallback = false
