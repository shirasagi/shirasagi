module Gws::Addon::Schedule::Facility
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :facilities, class_name: "Gws::Facility"

    permit_params facility_ids: []

    validate :validate_facility_double_booking, if: ->{ facilities.present? }

    scope :facility, ->(item) { where facility_ids: item.id }
  end

  private
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
