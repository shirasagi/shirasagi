class Gws::Affair2::Loader::DailyGroups::View < Gws::Affair2::Loader::DailyGroups::Base
  include Gws::Affair2::Loader::Common::TimeCardView

  def initialize(site, group, date, view_context)
    super(site, group, date)
    @view_context = view_context
  end

  def render_work_time(user)
    super(date, time_cards[user.id], time_card_records[user.id], load_records[user.id])
  end

  def render_over_time(user)
    super(date, time_cards[user.id], time_card_records[user.id], load_records[user.id], overtime_records[user.id])
  end

  def render_over_break_time(user)
    super(date, time_cards[user.id], time_card_records[user.id], load_records[user.id])
  end

  def render_over_compens(user)
    super(date, time_cards[user.id], time_card_records[user.id], load_records[user.id], overtime_records[user.id])
  end

  def render_leave(user)
    super(date, time_cards[user.id], time_card_records[user.id], load_records[user.id], leave_records[user.id])
  end
end
