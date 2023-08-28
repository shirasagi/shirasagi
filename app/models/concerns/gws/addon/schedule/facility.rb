module Gws::Addon::Schedule::Facility
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :duplicate_registered, type: DateTime
    embeds_ids :facilities, class_name: "Gws::Facility::Item"

    permit_params facility_ids: []

    validate :validate_facility_time, if: ->{ facilities.present? }
    validate :validate_reservable_members, if: ->{ facilities.present? }
    validate :validate_facility_double_booking, if: ->{ facilities.present? }
    validate :validate_facility_hours, if: ->{ facilities.present? }

    scope :facility, ->(item) { where facility_ids: item.id }
  end

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

    if cur_user
      max_days_limits = facilities.map do |facility|
        next if facility.allowed?(:edit, cur_user, site: cur_site || site)
        facility.max_days_limit
      end
    else
      max_days_limits = facilities.pluck(:max_days_limit)
    end

    now = Time.zone.now
    max_days_limit = max_days_limits.compact.min
    if max_days_limit && end_at > now + max_days_limit.days
      errors.add :base, I18n.t("gws/schedule.errors.faciliy_day_lte", count: max_days_limit)
    end

    reservation_start_date = facilities.pluck(:reservation_start_date).compact.max
    if reservation_start_date.present? && start_at < reservation_start_date
      message = I18n.t('gws/schedule.errors.less_than_max_date', date: I18n.l(reservation_start_date.localtime, format: :long))
      errors.add :start_at, message
    end

    reservation_end_date = facilities.pluck(:reservation_end_date).compact.min
    if reservation_end_date.present? && end_at >= reservation_end_date
      message = I18n.t('gws/schedule.errors.less_than_max_date', date: I18n.l(reservation_end_date.localtime, format: :long))
      errors.add :end_at, message
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
    return if facility_double_booking_plans.blank?

    if @cur_user && @cur_user.gws_role_permit_any?((@cur_site || site), :duplicate_private_gws_facility_plans)
      self.duplicate_registered = Time.zone.now
      return
    end

    errors.add :base, I18n.t('gws/schedule.errors.double_booking_facility')
    facility_double_booking_plans.each do |plan|
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

  def facility_double_booking_plans
    plans = self.class.ne(id: id).
      without_deleted.
      exists(duplicate_registered: false).
      where(site_id: site_id).
      any_in(facility_ids: facility_ids)
    if allday?
      plans = plans.where(:end_at.gt => start_on.in_time_zone.beginning_of_day, :start_at.lt => end_on.in_time_zone.end_of_day)
    else
      plans = plans.where(:end_at.gt => start_at, :start_at.lt => end_at)
    end
    plans
  end

  def reservation_errors
    return self.class.new.errors if facilities.blank?

    temp_errors = errors.dup
    errors.copy!(self.class.new.errors)
    validate_facility_time
    validate_reservable_members
    validate_facility_double_booking
    validate_facility_hours
    reservation_errors = errors.dup
    errors.copy!(temp_errors)
    reservation_errors
  end

  def reservation_status
    return 'free' if facilities.blank?
    return 'exist' if reservation_errors.present?
    return 'free' if facility_double_booking_plans.blank?

    user = cur_user || self.user
    site = cur_site || self.site

    return 'registered' if user.gws_role_permit_any?(site, :duplicate_private_gws_facility_plans)

    'exist'
  end
end
