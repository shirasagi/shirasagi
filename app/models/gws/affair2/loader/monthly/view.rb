class Gws::Affair2::Loader::Monthly::View < Gws::Affair2::Loader::Monthly::Base
  include Gws::Affair2::Loader::Common::TimeCardView

  def initialize(time_card, view_context)
    super(time_card)
    @view_context = view_context
  end

  def render_work_time(date)
    super(date, time_card, time_card_records[date], load_records[date])
  end

  def render_over_time(date)
    super(date, time_card, time_card_records[date], load_records[date], overtime_records[date])
  end

  def render_over_break_time(date)
    super(date, time_card, time_card_records[date], load_records[date])
  end

  def render_over_compens(date)
    super(date, time_card, time_card_records[date], load_records[date], overtime_records[date])
  end

  def render_leave(date)
    super(date, time_card, time_card_records[date], load_records[date], leave_records[date])
  end
end
