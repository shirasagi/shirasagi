class Gws::Affair2::Overtime::HolidayFile < Gws::Affair2::Overtime::File
  #include Gws::Addon::Affair2::OvertimeRecord
  #include Gws::Addon::Affair2::Approver
  #include Gws::Addon::GroupPermission
  #include Gws::Addon::History

  #permission_include_sub_groups

  attr_accessor :in_date, :in_start_hour, :in_start_minute,
    :in_close_hour, :in_close_minute

  seqid :id
  field :name, type: String
  field :long_name, type: String
  field :date, type: DateTime
  field :start_at, type: DateTime
  field :close_at, type: DateTime
  field :expense, type: String, default: "compens"
  field :compens_date, type: DateTime
  field :remark, type: String

  has_one :record, as: :file, class_name: "Gws::Affair2::Overtime::Record",
    inverse_of: :file, dependent: :destroy
  has_one :compens_record, as: :file, class_name: "Gws::Affair2::Leave::Record",
    inverse_of: :file, dependent: :destroy

  permit_params :name, :remark, :expense, :compens_date,
    :in_date, :in_start_hour, :in_start_minute,
    :in_close_hour, :in_close_minute

  before_validation :set_start_close
  validates :name, presence: true, length: { maximum: 80 }
  validate :validate_start_close
  validate :validate_compens_date
  validate :validate_time_card

  before_save :set_long_name
  after_save :save_record

  default_scope -> { order_by updated: -1 }

  def hour_options
    self.site ||= @cur_site
    hour_start = site.affair2_night_time_close_hour % 24
    hour_close = hour_start + 24
    hour_start.upto(hour_close).map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
  end

  def minute_options
    60.times.to_a.map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
  end

  def expense_options
    I18n.t("gws/affair2.options.expense").map { |k, v| [v, k] }
  end

  def compens?
    expense == "compens"
  end

  def settle?
    expense == "settle"
  end

  alias in_start_hour_options hour_options
  alias in_start_minute_options minute_options
  alias in_close_hour_options hour_options
  alias in_close_minute_options minute_options

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair2_overtime_holiday_file_path(site: site, id: id)
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair2_overtime_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    private_show_path
  end

  def start_close_label
    start_date = I18n.l(start_at.to_date, format: :long)
    close_date = I18n.l(close_at.to_date, format: :long)
    start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
    close_time = "#{close_at.hour}:#{format('%02d', close_at.minute)}"
    next_day = (start_date == close_date) ? "" : "翌"
    "#{start_date} #{start_time}#{I18n.t("ss.wave_dash")}#{next_day}#{close_time}"
  end

  def load_in_accessor
    return if start_at.nil? && close_at.nil?

    self.in_date ||= start_at.to_date
    self.in_start_hour ||= start_at.hour
    self.in_start_minute ||= start_at.min
    self.in_close_hour ||= (start_at.to_date == close_at.to_date) ? close_at.hour : close_at.hour + 24
    self.in_close_minute ||= close_at.min
  end

  private

  def set_long_name
    self.long_name = "#{name}（#{start_close_label}）"
  end

  def set_start_close
    self.in_date = Time.zone.parse(in_date).beginning_of_day rescue nil
    return if in_date.nil?

    self.date = in_date
    if in_start_hour && in_start_minute
      self.start_at = in_date.advance(hours: in_start_hour.to_i, minutes: in_start_minute.to_i, sec: 0) rescue nil
    end
    if in_close_hour && in_close_minute
      self.close_at = in_date.advance(hours: in_close_hour.to_i, minutes: in_close_minute.to_i, sec: 0) rescue nil
    end
  end

  def validate_start_close
    errors.add :start_at, :blank if self.start_at.nil?
    errors.add :close_at, :blank if self.close_at.nil?

    if start_at && close_at && start_at >= close_at
      errors.add :close_at, :after_than, time: t(:start_at)
    end
  end

  def validate_compens_date
    if settle?
      self.compens_date = nil
      return
    end
    self.errors.add :compens_date, :blank if compens_date.nil?
  end

  def validate_time_card
    return if errors.present?

    if time_card.nil?
      errors.add :base, "タイムカードが作成されていません。(#{date.year}年#{date.month}月)"
      return
    end
    if !time_card.regular_open?
      errors.add :base, "タイムカードの所定時間が設定されていません。(#{date.year}年#{date.month}月)"
      return
    end
    if compens_date
      if compens_time_card.nil?
        errors.add :base, "振替日のタイムカードが作成されていません。(#{compens_date.year}年#{compens_date.month}月)"
        return
      end
      if !compens_time_card.regular_open?
        errors.add :base, "振替日のタイムカードの所定時間が設定されていません。(#{compens_date.year}年#{compens_date.month}月)"
        return
      end
    end

    if time_card_record.regular_workday?
      errors.add :base, "日時が勤務日です。(#{I18n.l(date.to_date, format: :long)})"
    end
    if compens_date && compens_time_card_record.regular_holiday?
      errors.add :base, "振替日が休業日です。(#{I18n.l(compens_date.to_date, format: :long)})"
    end
  end

  def save_record
    # overtime
    item = record || Gws::Affair2::Overtime::Record.new
    item.cur_site = site
    item.cur_user = user
    item.file = self
    item.date = self.date
    item.expense = expense
    item.compens_date = compens_date
    if state == Workflow::Approver::WORKFLOW_STATE_APPROVE
      item.state = "order"
    else
      item.state = "request"
    end
    item.save!

    # compens leave
    if compens?
      item = compens_record || Gws::Affair2::Leave::Record.new
      item.cur_site = site
      item.cur_user = user
      item.file = self
      item.leave_type = "compens"
      item.allday = "allday"

      item.date = compens_date
      item.start_at = compens_time_card_record.regular_start
      item.close_at = compens_time_card_record.regular_close
      item.minutes = compens_time_card_record.regular_work_minutes
      #item.day_leave_minutes = day_leave_minutes

      if state == Workflow::Approver::WORKFLOW_STATE_APPROVE
        item.state = "order"
      else
        item.state = "request"
      end
      item.save!
    elsif compens_record
      compens_record.destroy
    end
  end

  def time_card
    return if user.nil? || site.nil? || date.nil?
    @time_card ||= Gws::Affair2::Attendance::TimeCard.site(site).user(user).
      where(date: date.change(day: 1)).first
  end

  def time_card_record
    return if time_card.nil?
    @time_card_record ||= time_card.records.find_by(date: date)
  end

  def compens_time_card
    return if user.nil? || site.nil? || compens_date.nil?
    @compens_time_card ||= Gws::Affair2::Attendance::TimeCard.site(site).user(user).
      where(date: compens_date.change(day: 1)).first
  end

  def compens_time_card_record
    return if time_card.nil?
    @compens_time_card_record ||= compens_time_card.records.find_by(date: compens_date)
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
