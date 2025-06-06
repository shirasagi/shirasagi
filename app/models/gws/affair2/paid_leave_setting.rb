class Gws::Affair2::PaidLeaveSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair2_admin_settings", :use

  attr_accessor :with_start, :with_close, :without_file_id

  seqid :id
  field :name, type: String
  field :year, type: Integer
  field :carryover_minutes, type: Integer, default: 0
  field :additional_minutes, type: Integer, default: 0
  belongs_to :attendance_setting, class_name: "Gws::Affair2::AttendanceSetting"

  validates :year, presence: true
  validates :carryover_minutes, presence: true
  validates :additional_minutes, presence: true
  validates :attendance_setting_id, presence: true, uniqueness: { scope: [:site_id, :year] }
  before_save :set_name

  permit_params :attendance_setting_id, :carryover_minutes, :additional_minutes, :order

  default_scope -> { order_by(order: 1, year: -1) }

  def effective_minutes
    carryover_minutes + additional_minutes
  end

  def used_minutes
    start = with_start || Time.zone.local(year, 1, 1)
    close = with_close || start.end_of_year

    records = Gws::Affair2::Leave::Record.site(site).user(user).
      and_approved.
      and_paid.
      and_between(start, close)

    records = records.where(file_id: { "$ne" => without_file_id }) if without_file_id
    records.pluck(:minutes).sum
  end

  def remind_minutes
    minutes = effective_minutes - used_minutes
    minutes > 0 ? minutes : 0
  end

  def leave_minutes_label(minutes, day_minutes, format = :leave_minutes_label1)
    days = minutes / day_minutes
    rem_minutes = minutes % day_minutes

    rem_hours = rem_minutes / 60
    rem_minutes %= 60
    I18n.t("gws/affair2.views.#{format}",
      minutes: minutes, days: days,
      rem_hours: rem_hours,
      rem_minutes: rem_minutes)
  end

  def carryover_minutes_label(day_minutes, format = :leave_minutes_label1)
    leave_minutes_label(carryover_minutes, day_minutes, format)
  end

  def additional_minutes_label(day_minutes, format = :leave_minutes_label1)
    leave_minutes_label(additional_minutes, day_minutes, format)
  end

  def effective_minutes_label(day_minutes, format = :leave_minutes_label1)
    leave_minutes_label(effective_minutes, day_minutes, format)
  end

  def used_minutes_label(day_minutes, format = :leave_minutes_label1)
    leave_minutes_label(used_minutes, day_minutes, format)
  end

  def remind_minutes_label(day_minutes, format = :leave_minutes_label1)
    leave_minutes_label(remind_minutes, day_minutes, format)
  end

  private

  def set_name
    self.user = attendance_setting.user
    self.name = "#{user.name}の年次有給（#{year}年）"
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
