module SS::Addon
  module TrashSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :trash_threshold, type: Integer, default: 1
      field :trash_threshold_unit, type: String, default: 'year'
      permit_params :trash_threshold, :trash_threshold_unit
    end

    def trash_threshold_unit_options
      %w(day week month year).collect do |unit|
        [I18n.t("ss.options.datetime_unit.#{unit}"), unit]
      end
    end
  end
end
