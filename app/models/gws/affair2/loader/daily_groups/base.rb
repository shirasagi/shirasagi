class Gws::Affair2::Loader::DailyGroups::Base < Gws::Affair2::Loader::Common::Base

  attr_reader :site, :group, :date,
    :users, :user_ids,
    :time_cards, :time_card_records,
    :overtime_records, :leave_records, :load_records

  def initialize(site, group, date)
    @site = site
    @group = group
    @date = date

    @users = @group.users.active.order_by_title(site).to_a
    @user_ids = @users.pluck(:id)
  end

  def load
    @time_cards = {}
    @time_card_records = {}
    @users.each do |user|
      time_card = Gws::Affair2::Attendance::TimeCard.site(site).user(user).
        where(date: date.beginning_of_month).first
      next if time_card.nil?

      @time_cards[user.id] = time_card
      @time_card_records[user.id] = time_card.records.find_by(date: date)
    end

    @overtime_records = {}
    items = Gws::Affair2::Overtime::Record.site(site).and(
      { "user_id" => { "$in" => user_ids } },
      { "state" => { "$ne" => "request" } },
      { "date" => date })
    items.each do |item|
      @overtime_records[item.user_id] ||= []
      @overtime_records[item.user_id] << item
    end

    @leave_records = {}
    items = Gws::Affair2::Leave::Record.site(site).and(
      { "user_id" => { "$in" => user_ids } },
      { "state" => { "$ne" => "request" } },
      { "date" => date })
    items.each do |item|
      @leave_records[item.user_id] ||= []
      @leave_records[item.user_id] << item
    end

    @load_records = {}
    @users.each do |user|
      record = @time_card_records[user.id]
      next if record.nil?

      item = OpenStruct.new
      set_basic(item, date, record)

      records = @leave_records[user.id].to_a
      set_leave_minutes(item, date, record, leave_records: records)
      set_work_minutes(item, date, record, leave_records: records)

      records = @overtime_records[user.id].to_a
      set_overtime_minutes(item, date, record, overtime_records: records)
      set_compens_overtime_minutes(item, date, record, overtime_records: records)
      set_settle_overtime_minutes(item, date, record, overtime_records: records)
      @load_records[user.id] = item
    end
  end
end
