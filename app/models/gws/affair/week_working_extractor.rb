class Gws::Affair::WeekWorkingExtractor
  def week_at(site_id, user_id, time)
    @time_cards ||= {}
    @annual_leave_dates ||= {}

    # 日曜始まり 土曜終わり
    start_of_week = time.to_date.advance(days: (-1 * time.wday))
    end_of_week = start_of_week.advance(days: 6)

    # 年次有給
    @annual_leave_dates[user_id] ||= begin
      items = Gws::Affair::LeaveFile.and([
        { site_id: site_id },
        { target_user_id: user_id },
        { state: "approve" },
        { leave_type: "annual_leave" },
      ]).to_a
      leave_dates = items.map { |item| item.leave_dates.map(&:date) }.flatten
      leave_dates = leave_dates.map(&:to_date)
      leave_dates
    end

    (start_of_week..end_of_week).map do |date|
      #タイムカード
      start_of_month = date.change(day: 1)
      @time_cards[user_id] ||= {}
      @time_cards[user_id][start_of_month] ||= begin
        time_card = Gws::Attendance::TimeCard.where(
          site_id: site_id,
          user_id: user_id,
          date: start_of_month
        ).first
        time_card ? time_card : "not found"
      end
      time_card = @time_cards[user_id][start_of_month]

      working_minutes = 0
      if time_card.class == Gws::Attendance::TimeCard
        record = time_card.records.where(date: date).first
        working_minutes = record ? (record.working_hour.to_i * 60 + record.working_minute.to_i) : 0
      end

      # 年次有給は勤務したとみなす
      annual_leave = false
      if working_minutes == 0
        if @annual_leave_dates[user_id].include?(date)
          working_minutes = 465 # 7.75時間とする
          annual_leave = true
        end
      end

      {
        date: date,
        working_minutes: working_minutes,
        annual_leave: annual_leave
      }
    end
  end
end
