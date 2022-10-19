class Gws::Affair::Attendance::TimeCard
  include Gws::Model::Attendance::TimeCard

  embeds_many :histories, class_name: 'Gws::Affair::Attendance::History'
  embeds_many :records, class_name: 'Gws::Affair::Attendance::Record'

  def punch(field_name, date, punch_at, duty_calendar)
    raise "unable to punch: #{field_name}" if !Gws::Attendance::Record.punchable_field_names.include?(field_name)

    date = (@cur_site || site).calc_attendance_date(date)
    record = self.records.where(date: date).first
    if record.blank?
      record = self.records.create(date: date)
    end

    record.duty_calendar = duty_calendar
    if record.send(field_name).present?
      errors.add :base, :already_punched
      return false
    end

    record.send("#{field_name}=", punch_at)
    self.histories.create(date: date, field_name: field_name, action: 'set', time: punch_at)

    # change gws user's presence
    @cur_user.presence_punch((@cur_site || site), field_name) if @cur_user
    record.save
  end

  def duty_calendar
    @_duty_calendar ||= begin
      user.effective_duty_calendar(site)
    rescue
      nil
    end
  end

  def total_working_minute
    records.map { |record| [record.working_hour.to_i, record.working_minute.to_i] }.
      sum{ |h, m| h * 60 + m }
  end

  def total_working_minute_label
    total = total_working_minute
    "#{total / 60}:#{format('%02d', total % 60)}"
  end
end
