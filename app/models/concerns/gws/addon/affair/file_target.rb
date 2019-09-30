module Gws::Addon::Affair::FileTarget
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :target_user, class_name: 'Gws::User'
    field :target_user_name, type: String
    field :target_user_kana, type: String
    field :target_user_staff_address_uid, type: String
    field :target_user_staff_category, type: String # 正職員、会計年度職員
    field :target_user_code, type: String

    belongs_to :target_group, class_name: 'Gws::Group'
    field :target_group_name, type: String
    field :target_group_code, type: String

    belongs_to :target_duty_calendar, class_name: 'Gws::Affair::DutyCalendar'
    field :target_duty_calendar_code, type: String

    permit_params :target_user_id
    permit_params :target_group_id

    before_validation :set_target_user_attributes, if: -> { target_user }

    validates :target_user_id, presence: true
    validates :target_user_name, presence: true
    validates :target_user_staff_address_uid, presence: true
    validates :target_user_staff_category, presence: true
    validates :target_user_code, presence: true

    validates :target_group_id, presence: true
    validates :target_group_name, presence: true
    validates :target_group_code, presence: true

    validates :target_duty_calendar_code, presence: true
  end

  def set_target_user_attributes
    self.target_user_name = target_user.name
    self.target_user_kana = target_user.kana
    self.target_user_staff_address_uid = target_user.staff_address_uid
    self.target_user_staff_category = target_user.staff_category

    if target_group
      self.target_group_name = target_group.name
      self.target_group_code = target_group.group_code
    end

    duty_calendar = target_user.default_duty_calendar(cur_site || site)
    if duty_calendar.class == Gws::Affair::DutyCalendar
      self.target_duty_calendar = duty_calendar
    end
    self.target_duty_calendar_code = duty_calendar.code
    self.target_user_code = [
      target_user_id.to_s,
      target_user_staff_address_uid,
      target_group_code,
      target_duty_calendar_code
    ].join("_")
  end
end
