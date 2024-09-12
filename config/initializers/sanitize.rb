# Sanitize
ActionView::Base.sanitized_allowed_tags.merge %w(font strike s u table thead tbody tr th td)
ActionView::Base.sanitized_allowed_attributes.merge %w(style border color face size align valign
  cellspacing cellpadding colspan rowspan)

Rails::HTML5::SafeListSanitizer.allowed_tags.merge %w(font strike s u table thead tbody tr th td)
Rails::HTML5::SafeListSanitizer.allowed_attributes.merge %w(style border color face size align valign
  cellspacing cellpadding colspan rowspan)
