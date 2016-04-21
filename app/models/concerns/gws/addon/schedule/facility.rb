module Gws::Addon::Schedule::Facility
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :facilities, class_name: "Gws::Facility::Item"

    permit_params facility_ids: []

    validate :validate_facility_time, if: ->{ facilities.present? }
    validate :validate_reservable_members, if: ->{ facilities.present? }
    validate :validate_facility_double_booking, if: ->{ facilities.present? }

    scope :facility, ->(item) { where facility_ids: item.id }
  end

  private
    def validate_facility_time
      min_time = 5
      if (end_at.to_i - start_at.to_i) < 60 * min_time
        errors.add :base, I18n.t("gws/schedule.errors.faciliy_time_gte", count: min_time)
      end
    end

    def validate_reservable_members
      return unless @cur_user

      facilities.each do |item|
        if !item.reservable?(@cur_user)
          errors.add :base, I18n.t('gws/schedule.errors.invalid_faciliy_reservate_member', name: item.name)
        end
      end
    end

    def validate_facility_double_booking
      plans = self.class.ne(id: id).
        where(site_id: site_id).
        where(:end_at.gt => start_at, :start_at.lt => end_at).
        any_in(facility_ids: facility_ids)
      return if plans.blank?

      facilities = []
      plans.each { |plan| facilities += (plan.facilities & self.facilities) }

      name = facilities.uniq.map(&:name).join(', ')
      errors.add :base, I18n.t('gws/schedule.errors.double_booking_facility', facility: name)
    end
end
