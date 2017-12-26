module Gws::Addon::Monitor
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :state, type: String, default: 'draft'
      field :released, type: DateTime
      field :release_date, type: DateTime
      field :close_date, type: DateTime

      permit_params :state, :released
      permit_params :release_date, :close_date

      validates :state, presence: true
      validates :released, datetime: true
      validates :release_date, datetime: true
      validates :close_date, datetime: true
      validate :validate_release_date
      after_validation :set_released, if: -> { state == 'public' }

      scope :and_public, ->(date = Time.zone.now) {
        where(state: "public", "$and" => [
          { "$or" => [{ release_date: nil }, { :release_date.lte => date }] },
          { "$or" => [{ close_date: nil }, { :close_date.gt => date }] },
        ])
      }
    end

    def state_with_release_date
      now = Time.zone.now
      return state if state != 'public'
      return 'closed' if release_date.present? && release_date > now
      return 'closed' if close_date.present? && close_date < now
      'public'
    end

    def state_options
      %w(draft public closed).map { |m| [I18n.t("gws/monitor.options.state.#{m}"), m] }
    end

    private

    def validate_release_date
      self.released ||= release_date if respond_to?(:released)

      if close_date.present? && release_date.present? && release_date >= close_date
        errors.add :close_date, :greater_than, count: t(:release_date)
      end
    end

    def set_released
      self.released ||= Time.zone.now
    end
  end
end
