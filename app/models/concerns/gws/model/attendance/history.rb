module Gws::Model::Attendance::History
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: 'gws_attendance_histories'

    embedded_in :time_card

    field :date, type: DateTime
    field :field_name, type: String
    field :time, type: DateTime
    field :action, type: String
    field :reason_type, type: String
    field :reason, type: String
  end

  def reason_type_options
    I18n.t("gws/attendance.options.reason_type").map { |k, v| [v, k] }
  end
end
