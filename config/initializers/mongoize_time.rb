# 英語形式の date/time との相互運用性を確保するため、いろんな箇所に monkey patch を当てる。
#
class String
  alias _shirasagi___mongoize_time__ __mongoize_time__
  def __mongoize_time__
    time_format = I18n.t("time.formats.picker", default: nil) rescue nil
    if time_format
      time = Time.zone.strptime(self, time_format) rescue nil
    end
    time ||= begin
      date_format = I18n.t("date.formats.picker", default: nil) rescue nil
      if date_format
        date_parts = Date._strptime(self, date_format) rescue nil
        if date_parts && date_parts[:leftover].blank?
          time = Time.zone.strptime(self, date_format) rescue nil
        end
      end
    end
    time ||= _shirasagi___mongoize_time__
    time
  end
end

class Date
  class << self
    alias _shirasagi_mongoize mongoize

    def mongoize(object)
      time = ::Time.mongoize(object)
      return time unless time

      time = time.in_time_zone
      ::Time.utc(time.year, time.month, time.day)
    end
  end
end

module ActiveModel
  module Type
    class Date
      alias _shirasagi_fallback_string_to_date fallback_string_to_date
      def fallback_string_to_date(string)
        date = ::Date.mongoize(string) rescue nil
        date || _shirasagi_fallback_string_to_date(string)
      end
    end

    class DateTime
      alias _shirasagi_fallback_string_to_time fallback_string_to_time
      def fallback_string_to_time(string)
        time = ::DateTime.mongoize(string) rescue nil
        time = time.localtime if time
        time || _shirasagi_fallback_string_to_time(string)
      end
    end

    # active attributes の :time は、調査したところうまく動作しない。
    # active attributes の :date と :datetime とはうまく動作しているので、
    # :date と :datetime にのみ monkey patch を当てるようにし、:time には当てない。
    #
    # class Time
    #   alias _shirasagi_fast_string_to_time fast_string_to_time
    #   def fast_string_to_time(string)
    #     time = _shirasagi_fast_string_to_time(string)
    #     time ||= ::Time.mongoize(string) rescue nil
    #     time
    #   end
    # end
  end
end
