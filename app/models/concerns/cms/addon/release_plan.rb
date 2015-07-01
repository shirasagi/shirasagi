module Cms::Addon
  module ReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :release_date, type: DateTime
      field :close_date, type: DateTime
      permit_params :release_date, :close_date

      validate :validate_release_date
      validate :validate_release_state
    end

    def validate_release_date
      self.released ||= release_date

      if close_date.present?
        if release_date.present? && release_date >= close_date
          errors.add :close_date, :greater_than, count: t(:release_date)
        end
      end
    end

    def validate_release_state
      return if errors.present?

      if state == "public"
        self.state = "ready" if release_date && release_date > Time.zone.now
        self.state = "closed" if close_date && close_date <= Time.zone.now
      end
    end
  end
end
