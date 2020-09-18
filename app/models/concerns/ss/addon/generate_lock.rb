module SS::Addon
  module GenerateLock
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :generate_lock_until, type: DateTime
      belongs_to :generate_lock_user, class_name: "SS::User"
      permit_params :generate_lock_until
      validate :validate_generate_lock
    end

    def generate_lock_enabled?
      SS.config.cms.generate_lock['disable'].blank?
    end

    def generate_locked?
      return false if !generate_lock_enabled?
      return false if generate_lock_until.blank?

      generate_lock_until >= Time.zone.now
    end

    private

    def validate_generate_lock
      return if !generate_lock_until_changed? || generate_lock_until.blank?

      begin
        if SS.config.cms.generate_lock['generate_lock_until'].present?
          term, unit = SS.config.cms.generate_lock['generate_lock_until'].split('.')
          term = term.to_i
          if generate_lock_until > Time.zone.now + term.send(unit)
            errors.add :generate_lock_until, :disallow_datetime_by_system
          end
        end
      rescue
        errors.add :generate_lock_until, :invalid
      end
    end
  end
end
