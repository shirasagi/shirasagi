class Gws::Affair2::AttendanceSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair2::AttendanceSetting::PaidLeave
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  attr_accessor :in_start_year, :in_start_month,
    :in_close_year, :in_close_month

  seqid :id
  field :name, type: String
  field :organization_uid, type: String
  field :start_date, type: DateTime
  field :close_date, type: DateTime
  belongs_to :duty_setting, class_name: "Gws::Affair2::DutySetting"
  belongs_to :leave_setting, class_name: "Gws::Affair2::LeaveSetting"
  has_many :paid_leave_settings, class_name: 'Gws::Affair2::PaidLeaveSetting', dependent: :destroy

  permit_params :organization_uid, :duty_setting_id, :leave_setting_id
  permit_params :in_start_year, :in_start_month,
    :in_close_year, :in_close_month

  before_validation :set_in_start_close
  validates :user_id, presence: true
  validates :organization_uid, presence: true
  validates :duty_setting_id, presence: true
  validates :leave_setting_id, presence: true
  validate :validate_start_close
  validate :validate_double_booking
  before_save :set_name

  default_scope -> { order_by(organization_uid: 1, start_date: -1) }

  def active_years
    (1900..2100)
  end

  def active_months
    (1..12)
  end

  def year_options
    active_years.map { |y| ["#{y}#{I18n.t("datetime.prompts.year")}", y] }.reverse
  end

  def month_options
    active_months.map { |m| ["#{m}#{I18n.t("datetime.prompts.month")}", m] }
  end

  private

  def set_name
    self.name = I18n.t("gws/affair2.formats.attendace_setting_name",
      duty: duty_setting.name, year: start_date.year, month: start_date.month)
  end

  def set_in_start_close
    if in_start_year && in_start_month
      self.in_start_year = active_years.include?(in_start_year.to_i) ? in_start_year.to_i : nil
      self.in_start_month = active_months.include?(in_start_month.to_i) ? in_start_month.to_i : nil
      self.start_date = DateTime.new(in_start_year, in_start_month).in_time_zone.beginning_of_day rescue nil
    end
    if in_close_year && in_close_month
      self.in_close_year = active_years.include?(in_close_year.to_i) ? in_close_year.to_i : nil
      self.in_close_month = active_months.include?(in_close_month.to_i) ? in_close_month.to_i : nil
      self.close_date = DateTime.new(in_close_year, in_close_month).in_time_zone.end_of_month.beginning_of_day rescue nil
    end
  end

  def validate_start_close
    if start_date.blank?
      errors.add :start_date, :blank
      return
    end
    if start_date && close_date && start_date >= close_date
      errors.add :close_date, :greater_than, count: t(:start_date)
    end
  end

  def validate_double_booking
    return if errors.present?

    items = self.class.site(site).user(user).ne(id: id).to_a
    items.each do |item|
      booking = false

      if close_date.nil? && item.close_date.nil?
        booking = true
      elsif close_date.nil?
        booking = (start_date <= item.close_date)
      elsif item.close_date.nil?
        booking = (close_date >= item.start_date)
      else
        booking = !(close_date < item.start_date || start_date > item.close_date)
      end

      if booking
        self.errors.add :base, "開始~終了が重複している設定が存在します。"
        break
      end
    end
  end

  class << self
    def and_current(date)
      self.where({ "$and" => [
        { start_date: { "$lte" => date.to_date } },
        { "$or" => [
          { close_date: { "$gte" => date.to_date } },
          { close_date: nil },
        ]}
      ]})
    end

    def and_between(start_date, close_date)
      start_date = start_date.to_date
      close_date = close_date.to_date
      return self.none if start_date > close_date

      self.where({ "$or" => [
        { "$and" => [
          { close_date: { "$ne" => nil } },
          { close_date: { "$gte" => start_date } },
          { start_date: { "$lte" => close_date } }
        ]},
        { "$and" => [
          { start_date: { "$lte" => close_date } },
          { close_date: nil }
        ]}
      ]})
    end

    def current_setting(site, user, date)
      self.site(site).user(user).and_current(date).first
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :user_name
      end
      criteria
    end
  end
end
