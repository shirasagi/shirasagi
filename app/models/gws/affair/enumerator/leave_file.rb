class Gws::Affair::Enumerator::LeaveFile < Gws::Affair::Enumerator::Base
  def initialize(items)
    @items = items.to_a
    super() do |y|
      y << bom + encode(headers.to_csv)
      @items.each do |item|
        line = []
        line << item.start_at.strftime("%Y/%m/%d %H:%M")
        line << item.end_at.strftime("%Y/%m/%d %H:%M")
        line << item.name
        line << item.target_user.try(:name)
        line << (item.label :leave_type)
        line << item.special_leave.try(:name)
        line << item.reason
        line << leave_hours(item)
        line << leave_minutes(item)
        y << encode(line.to_csv)
      end
    end
  end

  def leave_hours(item)
    minutes = item.leave_minutes_in_query
    (minutes.to_f / 60).floor(2).to_s.sub(/\.0$/, "")
  end

  def leave_minutes(item)
    item.leave_minutes_in_query
  end

  def headers
    terms = []
    terms << Gws::Affair::LeaveFile.t(:start_at)
    terms << Gws::Affair::LeaveFile.t(:end_at)
    terms << Gws::Affair::LeaveFile.t(:name)
    terms << Gws::Affair::LeaveFile.t(:target_user_id)
    terms << Gws::Affair::LeaveFile.t(:leave_type)
    terms << Gws::Affair::LeaveFile.t(:special_leave_id)
    terms << Gws::Affair::LeaveFile.t(:reason)
    terms << I18n.t("gws/affair.labels.leave_hours")
    terms << I18n.t("gws/affair.labels.leave_minutes")
    terms
  end
end
