module SS::Addon
  module GenerateLock
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :generate_lock_until, type: DateTime
    end

    def generate_lock_enabled?
      SS.config.cms.generate_lock['disable'].blank?
    end

    def generate_lock_options
      SS.config.cms.generate_lock['options'].collect do |opt|
        term, unit = opt.split('.')
        valid_unit = I18n.t("datetime.prompts.#{unit.singularize.downcase}", default: '')
        next if valid_unit.blank?
        [term + valid_unit + I18n.t('ss.units.during'), opt]
      rescue
        nil
      end.compact
    end

    def generate_locked?
      return false if !generate_lock_enabled?
      return false if generate_lock_until.blank?

      generate_lock_until >= Time.zone.now
    end

    def generate_lock(str)
      if !generate_lock_enabled?
        generate_unlock
        return
      end

      if !generate_lock_options.collect(&:last).include?(str)
        generate_unlock
        return
      end

      begin
        term, unit = str.split('.')
        term = term.to_i
        self.set(generate_lock_until: Time.zone.now + term.send(unit))
      rescue
        generate_unlock
      end
    end

    def generate_unlock
      self.set(generate_lock_until: nil)
    end
  end
end
