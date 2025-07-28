class Gws::Affair::OvertimeDayResult
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::Capital
  include Gws::Addon::Affair::FileTarget
  include Gws::Addon::Affair::OvertimeDayResult::Aggregate

  belongs_to :file, class_name: "Gws::Affair::OvertimeFile"

  field :date, type: DateTime
  field :date_year, type: Integer
  field :date_fiscal_year, type: Integer
  field :date_month, type: Integer

  field :start_at, type: DateTime
  field :end_at, type: DateTime

  field :is_holiday, type: ::Mongoid::Boolean
  field :duty_day_time_minute, type: Integer
  field :duty_night_time_minute, type: Integer
  field :leave_day_time_minute, type: Integer
  field :leave_night_time_minute, type: Integer
  field :week_in_compensatory_minute, type: Integer
  field :week_out_compensatory_minute, type: Integer
  field :holiday_compensatory_minute, type: Integer
  field :duty_day_in_work_time_minute, type: Integer

  field :break1_start_at, type: DateTime
  field :break1_end_at, type: DateTime
  field :break2_start_at, type: DateTime
  field :break2_end_at, type: DateTime
  field :break_time_minute, type: Integer

  field :result_closed, type: DateTime

  validates :file_id, presence: true
  validates :date, presence: true, uniqueness: { scope: [:site_id, :user_id, :file_id] }
  validates :date_year, presence: true
  validates :date_month, presence: true

  validates :is_holiday, presence: true
  validates :duty_day_time_minute, presence: true
  validates :duty_night_time_minute, presence: true
  validates :leave_day_time_minute, presence: true
  validates :leave_night_time_minute, presence: true
  validates :week_in_compensatory_minute, presence: true
  validates :week_out_compensatory_minute, presence: true
  validates :holiday_compensatory_minute, presence: true
  validates :break_time_minute, presence: true

  before_validation :set_file_target, if: ->{ file }

  default_scope -> { order_by(date: -1) }

  def day_time_minute
    is_holiday ? leave_day_time_minute : duty_day_time_minute
  end

  def night_time_minute
    is_holiday ? leave_night_time_minute : duty_night_time_minute
  end

  private

  def set_file_target
    self.target_user_id = file.target_user_id
    self.target_user_name = file.target_user.name
    self.target_user_kana = file.target_user.kana
    self.target_user_staff_address_uid = file.target_user_staff_address_uid
    self.target_user_staff_category = file.target_user.staff_category

    self.target_group_id = file.target_group_id
    self.target_group_name = file.target_group_name

    self.target_duty_calendar_id = file.target_duty_calendar_id
    self.target_user_code = file.target_user_code
  end
end
