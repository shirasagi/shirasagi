class Gws::Affair2::Loader::Monthly::Aggregation < Gws::Affair2::Loader::Monthly::Base
  def save!
    load

    if time_card.aggregation_month
      time_card.aggregation_month.destroy
    end

    @agg_month = Gws::Affair2::Aggregation::Month.new
    @agg_month.cur_site = site
    @agg_month.cur_user = user

    @agg_month.time_card = time_card
    @agg_month.date = month

    @agg_month.organization_uid = time_card.attendance_setting.organization_uid
    @agg_month.employee_type = time_card.attendance_setting.duty_setting.employee_type

    @agg_month.work_minutes1 = work_minutes1
    @agg_month.work_minutes2 = work_minutes2

    @agg_month.overtime_minutes = overtime_minutes

    @agg_month.overtime_short_minutes1 = overtime_short_minutes1
    @agg_month.overtime_day_minutes1 = overtime_day_minutes1
    @agg_month.overtime_night_minutes1 = overtime_night_minutes1
    @agg_month.compens_overtime_day_minutes1 = compens_overtime_day_minutes1
    @agg_month.compens_overtime_night_minutes1 = compens_overtime_night_minutes1
    @agg_month.settle_overtime_day_minutes1 = settle_overtime_day_minutes1
    @agg_month.settle_overtime_night_minutes1 = settle_overtime_night_minutes1

    @agg_month.overtime_short_minutes2 = overtime_short_minutes2
    @agg_month.overtime_day_minutes2 = overtime_day_minutes2
    @agg_month.overtime_night_minutes2 = overtime_night_minutes2
    @agg_month.compens_overtime_day_minutes2 = compens_overtime_day_minutes2
    @agg_month.compens_overtime_night_minutes2 = compens_overtime_night_minutes2
    @agg_month.settle_overtime_day_minutes2 = settle_overtime_day_minutes2
    @agg_month.settle_overtime_night_minutes2 = settle_overtime_night_minutes2

    @agg_month.leave_minutes = leave_minutes
    leave = []
    leave_minutes_hash.each do |leave_type, minutes|
      item = Gws::Affair2::Aggregation::Leave.new
      item.leave_type = leave_type
      item.minutes = minutes
      leave << item
    end
    @agg_month.leave = leave
    @agg_month.save!

    load_records.each do |date, record|
      @agg_day = Gws::Affair2::Aggregation::Day.new
      @agg_day.cur_site = site
      @agg_day.cur_user = user

      @agg_day.month = @agg_month
      @agg_day.date = date

      @agg_day.organization_uid = time_card.attendance_setting.organization_uid
      @agg_day.employee_type = time_card.attendance_setting.duty_setting.employee_type

      @agg_day.work_minutes1 = record.work_minutes1
      @agg_day.work_minutes2 = record.work_minutes2

      @agg_day.overtime_minutes = record.overtime_minutes
      @agg_day.overtime_short_minutes1 = record.overtime_short_minutes1
      @agg_day.overtime_day_minutes1 = record.overtime_day_minutes1
      @agg_day.overtime_night_minutes1 = record.overtime_night_minutes1
      @agg_day.compens_overtime_day_minutes1 = record.compens_overtime_day_minutes1
      @agg_day.compens_overtime_night_minutes1 = record.compens_overtime_night_minutes1
      @agg_day.settle_overtime_day_minutes1 = record.settle_overtime_day_minutes1
      @agg_day.settle_overtime_night_minutes1 = record.settle_overtime_night_minutes1

      @agg_day.overtime_short_minutes2 = record.overtime_short_minutes2
      @agg_day.overtime_day_minutes2 = record.overtime_day_minutes2
      @agg_day.overtime_night_minutes2 = record.overtime_night_minutes2
      @agg_day.compens_overtime_day_minutes2 = record.compens_overtime_day_minutes2
      @agg_day.compens_overtime_night_minutes2 = record.compens_overtime_night_minutes2
      @agg_day.settle_overtime_day_minutes2 = record.settle_overtime_day_minutes2
      @agg_day.settle_overtime_night_minutes2 = record.settle_overtime_night_minutes2

      @agg_day.leave_minutes = record.leave_minutes
      leave = []
      record.leave_minutes_hash.each do |leave_type, minutes|
        item = Gws::Affair2::Aggregation::Leave.new
        item.leave_type = leave_type
        item.minutes = minutes
        leave << item
      end
      @agg_day.leave = leave
      @agg_day.save!
    end
  end
end
