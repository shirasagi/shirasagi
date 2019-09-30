class Gws::Attendance::History
  extend SS::Translation
  include SS::Document

  embedded_in :time_card

  field :date, type: DateTime
  field :field_name, type: String
  field :time, type: DateTime
  field :action, type: String
  field :reason_type, type: String
  field :reason, type: String

  def reason_type_options
    I18n.t("gws/attendance.options.reason_type").map { |k, v| [v, k] }
  end
end
