module Gws::Addon::Affair2
  module DutySetting
    module Workday
      extend ActiveSupport::Concern
      extend SS::Addon

      WORKDAY_TYPE = %w(sunday monday tuesday wednesday thursday friday saturday national_holiday special_holiday).freeze

      included do
        WORKDAY_TYPE.each do |wday|
          field "#{wday}_type", type: String, default: default_workday_type(wday)
          permit_params "#{wday}_type"
          validates "#{wday}_type", presence: true, inclusion: { in: %w(workday holiday), allow_blank: true }
        end
      end

      def wday_type_options
        %w(workday holiday).map do |v|
          [ I18n.t("gws/affair2.options.wday_type.#{v}"), v ]
        end
      end

      WORKDAY_TYPE.each do |wday|
        alias_method "#{wday}_type_options", :wday_type_options
      end

      def special_holiday?(date)
        @special_holiday ||= Gws::Affair2::SpecialHoliday.site(site).to_a.index_by(&:date)
        @special_holiday[date.to_datetime]
      end

      def national_holiday?(date)
        date.to_date.national_holiday?
      end

      def regular_holiday(date)
        worktime_constant? ? regular_holiday_constant(date) : regular_holiday_variable(date)
      end

      def regular_holiday_constant(date)
        if special_holiday?(date)
          return special_holiday_type
        end
        if national_holiday?(date)
          return national_holiday_type
        end

        wday = %w(sunday monday tuesday wednesday thursday friday saturday)[date.wday]
        send("#{wday}_type")
      end

      # 不定期勤務は一先ず土日祝を休業日としてタイムカードに設定し、後で編集させる
      def regular_holiday_variable(date)
        if special_holiday?(date)
          return "holiday"
        end
        if national_holiday?(date)
          return "holiday"
        end

        if date.wday == 0 || date.wday == 6
          "holiday"
        else
          "workday"
        end
      end

      module ClassMethods
        def default_workday_type(wday)
          @@_default_workday ||= SS.config.affair2.dig("default_duty", "workday")
          @@_default_workday[wday.to_s]
        end
      end
    end
  end
end
