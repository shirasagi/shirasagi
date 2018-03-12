module Gws::Addon::Schedule::Facility
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :facilities, class_name: "Gws::Facility::Item"

    permit_params facility_ids: []

    validate :validate_facility_time, if: ->{ facilities.present? }
    validate :validate_reservable_members, if: ->{ facilities.present? }
    validate :validate_facility_double_booking, if: ->{ facilities.present? }
    validate :validate_facility_hours, if: ->{ facilities.present? }

    scope :facility, ->(item) { where facility_ids: item.id }
  end

  private

  def validate_facility_time
    duration = end_at.to_i - start_at.to_i
    min_minutes_limit = facilities.pluck(:min_minutes_limit).compact.max
    if min_minutes_limit && duration < 60 * min_minutes_limit
      errors.add :base, I18n.t("gws/schedule.errors.faciliy_time_gte", count: min_minutes_limit)
    end

    max_minutes_limit = facilities.pluck(:max_minutes_limit).compact.min
    if max_minutes_limit
      if allday?
        errors.add :base, I18n.t("gws/schedule.errors.unable_to_reserve_all_days", count: max_minutes_limit)
      elsif duration > 60 * max_minutes_limit
        errors.add :base, I18n.t("gws/schedule.errors.faciliy_time_lte", count: max_minutes_limit)
      end
    end

    now = Time.zone.now
    max_days_limit = facilities.pluck(:max_days_limit).compact.min
    if max_days_limit && end_at > now + max_days_limit.days
      errors.add :base, I18n.t("gws/schedule.errors.faciliy_day_lte", count: max_days_limit)
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
    plans = self.class.ne(id: id).without_deleted.
      where(site_id: site_id).
      where(:end_at.gt => start_at, :start_at.lt => end_at).
      any_in(facility_ids: facility_ids)
    return if plans.blank?

    errors.add :base, I18n.t('gws/schedule.errors.double_booking_facility')
    plans.each do |plan|
      msg = Gws::Schedule::PlansController.helpers.term(plan)
      msg += " " + plan.facilities.map(&:name).join(',')
      if plan.user.present?
        msg += " " + plan.user.name
        msg += " (#{plan.user.t(:tel_ext_short)}:#{plan.user.tel_ext})" if plan.user.tel_ext.present?
      end
      errors.add :base, msg
    end
  end

  def validate_facility_hours
    return if allday?
    site = @cur_site || self.site

    min_hour = site.facility_min_hour
    max_hour = site.facility_max_hour

    min = "#{min_hour}0000".to_i
    max = "#{max_hour}0000".to_i

    if start_at.strftime('%H%M%S').to_i < min || max < end_at.strftime('%H%M%S').to_i
      min = site.facility_min_hour
      max = site.facility_max_hour
      errors.add :base, I18n.t('gws/schedule.errors.over_than_facility_hours', min: min_hour, max: max_hour)
    end
  end
end
