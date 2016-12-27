# Sanitize
ActionView::Base.sanitized_allowed_tags.merge %w(font strike u table thead tbody tr th td)
ActionView::Base.sanitized_allowed_attributes.merge %w(style border color face size align valign
                                                       cellspacing cellpadding colspan rowspan)
