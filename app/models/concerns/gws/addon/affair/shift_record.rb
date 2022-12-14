module Gws::Addon::Affair::ShiftRecord
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :shift_records, class_name: 'Gws::Affair::ShiftRecord', dependent: :destroy, inverse_of: :shift_calendar
  end

  def shift_record(date)
    @_shift_records ||= begin
      h = {}
      shift_records.each do |item|
        h[item.date.strftime("%Y/%m/%d")] = item
      end
      h
    end
    @_shift_records[date.strftime("%Y/%m/%d")]
  end
end
