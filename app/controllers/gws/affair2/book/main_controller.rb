class Gws::Affair2::Book::MainController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair2::BaseFilter

  def index
    case params[:form]
    when "time_cards"
      redirect_to_time_cards
    when "workday_overtime"
      redirect_to_workday_overtime
    when "holiday_overtime"
      redirect_to_holiday_overtime
    when "paid_leave"
      redirect_to_paid_leave
    when "other_leave"
      redirect_to_other_leave
    else
      redirect_to_first_link
    end
  end

  def redirect_to_first_link
    if Gws::Affair2::Book::WorkdayOvertime.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to_workday_overtime
      return
    end
    if Gws::Affair2::Book::HolidayOvertime.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to_holiday_overtime
      return
    end
    if Gws::Affair2::Book::PaidLeave.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to_paid_leave
      return
    end
    if Gws::Affair2::Book::OtherLeave.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to_other_leave
      return
    end
    redirect_to_time_cards
  end

  def redirect_to_workday_overtime
    year_month = Gws::Affair2::Book::WorkdayOvertime.year_month(@cur_site, @attendance_date)
    redirect_to gws_affair2_book_workday_overtime_index_path(year_month: year_month)
  end

  def redirect_to_holiday_overtime
    year_month = Gws::Affair2::Book::HolidayOvertime.year_month(@cur_site, @attendance_date)
    redirect_to gws_affair2_book_holiday_overtime_index_path(year_month: year_month)
  end

  def redirect_to_paid_leave
    year = Time.zone.today.year
    redirect_to gws_affair2_book_paid_leave_index_path(year: year)
  end

  def redirect_to_other_leave
    year = Time.zone.today.year
    redirect_to gws_affair2_book_other_leave_index_path(year: year)
  end

  def redirect_to_time_cards
    fiscal_year = Gws::Affair2::Book::TimeCard.fiscal_year(@cur_site, @attendance_date)
    redirect_to gws_affair2_book_time_cards_path(fiscal_year: fiscal_year)
  end
end
