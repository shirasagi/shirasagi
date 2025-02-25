class Gws::Affair2::Leave::Record
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site

  belongs_to :file, class_name: "Object", polymorphic: true
  field :date, type: DateTime
  field :leave_type, type: String
  field :state, type: String, default: "request"

  field :start_at, type: DateTime # 終日の場合は所定開始
  field :close_at, type: DateTime # 終日の場合は所定終了
  field :minutes, type: Integer # タイムカードに設定されている所定による休暇時間（所定終了 - 所定開始 - 休憩時間）
  field :allday, type: String

  field :day_leave_minutes, type: Integer # 雇用区分に設定されている1日の休暇時間

  validates :date, presence: true
  validates :leave_type, presence: true
  #validate :validate_start_close

  #def validate_start_close
  #  if start_at && close_at && start_at >= close_at
  #    errors.add :close_at, :after_than, time: t(:start_at)
  #  end
  #  if break_start_at && break_close_at && break_start_at > break_close_at
  #    errors.add :break_close_at, :after_than, time: t(:break_start_at)
  #  end
  #end

  def name
    if allday == "allday"
      "#{label(:leave_type)}(終日)"
    else
      start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
      close_time = "#{close_at.hour}:#{format('%02d', close_at.minute)}"
      "#{label(:leave_type)}(#{start_time}#{I18n.t("ss.wave_dash")}#{close_time})"
    end
  end

  def state_options
    [
      ["申請", "request"],
      ["命令", "order"]
    ]
  end

  def allday?
    allday == "allday"
  end

  def leave_type_options
    Gws::Affair2::LeaveSetting.leave_type_options
  end

  class << self
    def and_approved
      self.where(state: { "$ne" => "request" })
    end

    def and_paid
      self.where(leave_type: "paid")
    end

    def and_between(start_date, close_date)
      start_date = start_date.to_date
      close_date = close_date.to_date
      return self.none if start_date > close_date

      self.where({ "$and" => [
        { "date" => { "$gte" => start_date } },
        { "date" => { "$lte" => close_date } }
      ]})
    end
  end

  #def validate_state
  #  return if file.nil?
  #  if state == "request" && file.workflow_state == Workflow::Approver::WORKFLOW_STATE_APPROVE
  #    self.state = "order"
  #  end
  #end
end
