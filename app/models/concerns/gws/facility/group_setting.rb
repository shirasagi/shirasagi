module Gws::Facility::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :facility_min_hour, type: Integer, default: 8
    field :facility_max_hour, type: Integer, default: 22

    permit_params :facility_min_hour, :facility_max_hour

    validate :validate_facility_hours, if: ->{ facility_min_hour.present? && facility_max_hour.present? }
  end

  def facility_min_hour_options
    (0..24).map { |m| [m, m] }
  end

  def facility_max_hour_options
    facility_min_hour_options
  end

  def facility_min_time
    hour = self[:facility_min_hour].presence || 8
    "#{hour}:00"
  end

  def facility_max_time
    hour = self[:facility_max_hour].presence || 22
    "#{hour}:00"
  end

  private
    def validate_facility_hours
      if facility_min_hour >= facility_max_hour
        errors.add :facility_max_hour, :greater_than, count: t(:facility_min_hour)
      end
    end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Facility::Item.allowed?(action, user, opts)
      return true if Gws::Facility::Category.allowed?(action, user, opts)
      #super
      false
    end
  end
end
