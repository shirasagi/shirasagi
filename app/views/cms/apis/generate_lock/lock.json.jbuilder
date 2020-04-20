json.generate_lock_until(@cur_site.generate_lock_until.present? ? I18n.l(@cur_site.generate_lock_until, format: :long) : '')
