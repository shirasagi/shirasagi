module Cms::Addon
  module DefaultReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :default_release_plan_state, type: String, default: 'disabled'
      field :default_release_days_after, type: Integer
      field :default_close_days_after, type: Integer

      permit_params :default_release_plan_state, :default_release_days_after, :default_close_days_after

      validates :default_release_days_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: ->{ default_release_plan_enabled? }
      validates :default_close_days_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: ->{ default_release_plan_enabled? }
      validate :validate_default_close_days_after
    end

    def default_release_plan_state_options
      %w(disabled enabled).map do |v|
        [ I18n.t("views.options.state.#{v}"), v ]
      end
    end

    def default_release_plan_enabled?
      self.default_release_plan_state == 'enabled'
    end

    def default_release_plan_disabled?
      !default_release_plan_enabled?
    end

    private
      def validate_default_close_days_after
        return if default_release_days_after.blank?
        return if default_close_days_after.blank?

        if default_release_days_after >= default_close_days_after
          errors.add :default_close_days_after, :greater_than, count: t(:default_release_days_after)
        end
      end
  end
end
