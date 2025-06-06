class Gws::Affair2::Aggregation::Month
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site

  belongs_to :time_card, class_name: "Gws::Affair2::Attendance::TimeCard"
  has_many :days, class_name: "Gws::Affair2::Aggregation::Day", dependent: :destroy, inverse_of: :month

  ##
  field :date, type: DateTime
  field :employee_type, type: String
  field :organization_uid, type: String
  field :work_minutes1, type: Integer # 執務時間
  field :work_minutes2, type: Integer # 執務時間
  ##
  field :overtime_minutes, type: Integer
  # 30h未満
  field :overtime_short_minutes1, type: Integer
  field :overtime_day_minutes1, type: Integer
  field :overtime_night_minutes1, type: Integer
  field :compens_overtime_day_minutes1, type: Integer
  field :compens_overtime_night_minutes1, type: Integer
  field :settle_overtime_day_minutes1, type: Integer
  field :settle_overtime_night_minutes1, type: Integer
  # 30h以上
  field :overtime_short_minutes2, type: Integer
  field :overtime_day_minutes2, type: Integer
  field :overtime_night_minutes2, type: Integer
  field :compens_overtime_day_minutes2, type: Integer
  field :compens_overtime_night_minutes2, type: Integer
  field :settle_overtime_day_minutes2, type: Integer
  field :settle_overtime_night_minutes2, type: Integer
  ##
  embeds_many :leave, class_name: 'Gws::Affair2::Aggregation::Leave'
  field :leave_minutes, type: Integer

  default_scope -> { order_by(organization_uid: 1, date: 1) }

  def date_label
    date.strftime("%Y/%-m")
  end

  def employee_type_options
    I18n.t("gws/affair2.options.employee_type").map { |k, v| [v, k] }
  end

  class << self
    def leave_type_options
      Gws::Affair2::LeaveSetting.leave_type_options
    end
  end

  leave_type_options.each do |name, leave_type|
    define_method("leave_#{leave_type}_minutes") do
      item = find_leave(leave_type)
      item ? item.minutes : 0
    end
  end

  private

  def find_leave(leave_type)
    leave.to_a.find { |item| item.leave_type == leave_type.to_s }
  end

  class << self
    def and_viewable(month:, employee_type:, form:)
      self.where(date: month, employee_type: employee_type)
    end

    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :organization_uid
      end
      criteria
    end
  end
end
