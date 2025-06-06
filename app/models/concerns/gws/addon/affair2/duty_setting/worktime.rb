module Gws::Addon::Affair2
  module DutySetting
    module Worktime
      extend ActiveSupport::Concern
      extend SS::Addon

      included do
        class_variable_set(
          :@@default_duty_worktime,
          SS.config.affair2.dig("default_duty", "worktime").with_indifferent_access)

        delegate :time_to_min, :min_to_time, to: Gws::Affair2::Utils

        # 所定労働時間(日)
        field :worktime_day_minute, type: Integer
        before_validation :set_worktime_day_minute
        #validates :worktime_day_minute, presence: true, numericality: { greater_than: 0 }

        # 所定労働時間(勤務)
        field :worktime_of_wday, default: "disabled"
        permit_params :worktime_of_wday

        field :start_at_hour, type: Integer, default: default_duty_worktime[:start_hour]
        field :start_at_minute, type: Integer, default: default_duty_worktime[:start_minute]
        field :close_at_hour, type: Integer, default: default_duty_worktime[:close_hour]
        field :close_at_minute, type: Integer, default: default_duty_worktime[:close_minute]
        field :break_minutes_at, type: Integer, default: default_duty_worktime[:break_minutes]
        permit_params :start_at_hour, :start_at_minute
        permit_params :close_at_hour, :close_at_minute
        permit_params :break_minutes_at

        validates :start_at_hour, presence: true,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
        validates :start_at_minute, presence: true,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
        validates :close_at_hour, presence: true,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
        validates :close_at_minute, presence: true,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }

        (0..6).each do |wday|
          field "start_at_hour_#{wday}", type: Integer, default: default_duty_worktime[:start_hour]
          field "start_at_minute_#{wday}", type: Integer, default: default_duty_worktime[:start_minute]
          field "close_at_hour_#{wday}", type: Integer, default: default_duty_worktime[:close_hour]
          field "close_at_minute_#{wday}", type: Integer, default: default_duty_worktime[:close_minute]
          field "break_minutes_at_#{wday}", type: Integer, default: default_duty_worktime[:break_minutes]
          permit_params "start_at_hour_#{wday}", "start_at_minute_#{wday}"
          permit_params "close_at_hour_#{wday}", "close_at_minute_#{wday}"
          permit_params "break_minutes_at_#{wday}"

          validates "start_at_hour_#{wday}", presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
          validates "start_at_minute_#{wday}", presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
          validates "close_at_hour_#{wday}", presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
          validates "close_at_minute_#{wday}", presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
        end
      end

      def format_minutes(minutes)
        (minutes.to_i > 0) ? "#{minutes / 60}:#{format("%02d", (minutes % 60))}" : "--:--"
      end

      def long_name
        "#{name} (#{label(:employee_type)})"
      end

      def worktime_of_wday_enabled?
        worktime_of_wday == "enabled"
      end

      def worktime_of_wday_disabled?
        !worktime_of_wday_enabled?
      end

      def hour_options
        (0..23).map do |h|
          [ I18n.t('gws/attendance.hour', count: h), h.to_s ]
        end
      end

      def minute_options
        0.step(59, 5).map do |m|
          [ I18n.t('gws/attendance.minute', count: m), m.to_s ]
        end
      end

      def break_minutes_options
        0.step(240, 5).map do |m|
          [ I18n.t('gws/attendance.minute', count: m), m.to_s ]
        end
      end

      def set_worktime_day_minute
        if worktime_constant?
          diff = (close_at_hour.to_i * 60 + close_at_minute.to_i) - (start_at_hour.to_i * 60 + start_at_minute.to_i)
          diff -= break_minutes_at
          self.worktime_day_minute = (diff > 0) ? diff : 0
        else
          self.worktime_day_minute = nil
        end
      end

      alias_method "start_at_hour_options", "hour_options"
      alias_method "start_at_minute_options", "minute_options"
      alias_method "close_at_hour_options", "hour_options"
      alias_method "close_at_minute_options", "minute_options"
      alias_method "break_minutes_at_options", "break_minutes_options"
      (0..6).each do |wday|
        alias_method "start_at_hour_#{wday}_options", "hour_options"
        alias_method "start_at_minute_#{wday}_options", "minute_options"
        alias_method "close_at_hour_#{wday}_options", "hour_options"
        alias_method "close_at_minute_#{wday}_options", "minute_options"
        alias_method "break_minutes_at_#{wday}_options", "break_minutes_options"
      end

      def start_time(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        hour = start_hour(time)
        min = start_minute(time)
        time.change(hour: hour, min: min, sec: 0)
      end

      def close_time(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        hour = close_hour(time)
        min = close_minute(time)
        time.change(hour: hour, min: min, sec: 0)
      end

      def break_minutes(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        return break_minutes_at if time.nil?
        worktime_of_wday_disabled? ? break_minutes_at : send("break_minutes_at_#{time.wday}")
      end

      def work_minutes(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        minutes = time_to_min(close_time(time)) - time_to_min(start_time(time)) - break_minutes(time)
        minutes > 0 ? minutes : 0
      end

      def start_hour(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        return start_at_hour if time.nil?
        worktime_of_wday_disabled? ? start_at_hour : send("start_at_hour_#{time.wday}")
      end

      def start_minute(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        return start_at_minute if time.nil?
        worktime_of_wday_disabled? ? start_at_minute : send("start_at_minute_#{time.wday}")
      end

      def close_hour(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        return close_at_hour if time.nil?
        worktime_of_wday_disabled? ? close_at_hour : send("close_at_hour_#{time.wday}")
      end

      def close_minute(time = nil)
        return nil if worktime_variable?
        return nil if regular_holiday(time) == "holiday"
        return close_at_minute if time.nil?
        worktime_of_wday_disabled? ? close_at_minute : send("close_at_minute_#{time.wday}")
      end

      module ClassMethods
        def default_duty_worktime
          class_variable_get(:@@default_duty_worktime)
        end
      end
    end
  end
end
