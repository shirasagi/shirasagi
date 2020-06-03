module SS::Addon
  module Release
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      class_variable_set(:@@_hide_released_field, nil)

      field :state, type: String, default: "public", overwrite: true
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
      after_validation :set_released, if: -> { state == "public" }

      scope :and_public, ->(date = Time.zone.now) {
        where(state: "public", "$and" => [
          { "$or" => [{ release_date: nil }, { :release_date.lte => date }] },
          { "$or" => [{ close_date: nil }, { :close_date.gt => date }] },
        ])
      }
      scope :and_closed, ->(date = Time.zone.now) {
        where("$and" => [
          { "$or" => [{ state: "closed" }, { :release_date.gt => date }, { :close_date.lte => date }] }
        ])
      }
    end

    def closed?(date = Time.zone.now)
      return true if state != "public"
      return true if release_date.present? && release_date > date
      return true if close_date.present? && close_date <= date

      false
    end

    def public?(date = Time.zone.now)
      !closed?(date)
    end

    def updated_after_released?
      updated.to_i > created.to_i && updated.to_i > released.to_i
    end

    def state_with_release_date
      public? ? "public" : "closed"
    end

    def state_options
      %w(public closed).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
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

    module ClassMethods
      def released_field_shown?
        !class_variable_get(:@@_hide_released_field)
      end

      private

      def hide_released_field
        class_variable_set(:@@_hide_released_field, true)
      end
    end
  end
end
