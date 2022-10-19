module Gws::Model::Attendance::Record
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    cattr_accessor(:punchable_field_names)

    self.punchable_field_names = %w(enter leave)

    field :date, type: DateTime
    field :enter, type: DateTime
    field :leave, type: DateTime
    SS.config.gws.attendance['max_break'].times do |i|
      field "break_enter#{i + 1}", type: DateTime
      field "break_leave#{i + 1}", type: DateTime
      self.punchable_field_names << "break_enter#{i + 1}"
      self.punchable_field_names << "break_leave#{i + 1}"
    end
    field :memo, type: String
    self.punchable_field_names = self.punchable_field_names.freeze
  end

  def find_latest_history(field_name)
    criteria = time_card.histories.where(date: date.in_time_zone('UTC'), field_name: field_name)
    criteria.order_by(created: -1).first
  end

  def date_range
    changed_minute = time_card.site.attendance_time_changed_minute
    hour, min = changed_minute.divmod(60)

    lower_bound = date.in_time_zone.change(hour: hour, min: min, sec: 0)
    upper_bound = lower_bound + 1.day

    # lower_bound から upper_bound。ただし upper_bound は範囲に含まない。
    lower_bound...upper_bound
  end
end
