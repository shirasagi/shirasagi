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
        next if item.reservable_member_ids.blank?
        if !item.reservable_member_ids.include?(@cur_user.id)
          errors.add :base, I18n.t('gws/schedule.errors.invalid_faciliy_reservate_member', name: item.name)
        end
      end
    end

    def validate_facility_double_booking
      return unless self.class.ne(id: id).
        where(site_id: site_id).
        #between_dates(start_at, end_at).
        where(:end_at.gt => start_at, :start_at.lt => end_at).
        any_in(facility_ids: facility_ids).
        exists?

      errors.add :facility_ids, :duplicate
    end
end
