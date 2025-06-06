module Gws::Addon::Affair2
  module DutySetting
    module Leave
      extend ActiveSupport::Concern
      extend SS::Addon

      included do
        attr_accessor :in_day_leave_hour, :in_day_leave_minute

        field :day_leave_minutes, type: Integer, default: SS.config.affair2.dig("default_duty", "day_leave_minutes")

        permit_params :in_day_leave_hour, :in_day_leave_minute

        before_validation :set_day_leave_minutes
        validates :day_leave_minutes, numericality: { greater_than_or_equal_to: 0 }
      end

      def in_day_leave_hour_options
        (0..23).map { |h| [ I18n.t("gws/attendance.hour", count: h), h ] }
      end

      def in_day_leave_minute_options
        0.step(45, 15).map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
      end

      def load_in_accessor
        self.in_day_leave_hour = day_leave_minutes / 60
        self.in_day_leave_minute = day_leave_minutes % 60
      end

      private

      def set_day_leave_minutes
        return if in_day_leave_hour.blank?
        return if in_day_leave_minute.blank?
        self.day_leave_minutes = in_day_leave_hour.to_i * 60 + in_day_leave_minute.to_i
      end
    end
  end
end
