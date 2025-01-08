module SS::Addon
  module TrashSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :trash_threshold, type: Integer, default: SS::DEFAULT_TRASH_THRESHOLD
      field :trash_threshold_unit, type: String, default: SS::DEFAULT_TRASH_THRESHOLD_UNIT
      permit_params :trash_threshold, :trash_threshold_unit
    end

    def trash_threshold_unit_options
      %w(day week month year).collect do |unit|
        [I18n.t("ss.options.datetime_unit.#{unit}"), unit]
      end
    end

    def trash_threshold_in_days
      threshold = trash_threshold || SS::DEFAULT_TRASH_THRESHOLD
      unit = trash_threshold_unit.presence || SS::DEFAULT_TRASH_THRESHOLD_UNIT
      case unit.singularize.downcase
      when 'day'
        Integer(threshold).days
      when 'week'
        Integer(threshold).weeks
      when 'month'
        Integer(threshold).months
      else # 'year'
        Integer(threshold).years
      end
    end
  end
end
