module Gws::Affair::LeaveFile::Compensatory
  extend ActiveSupport::Concern

  included do
    # 週内振替
    belongs_to :week_in_compensatory_file, class_name: "Gws::Affair::OvertimeFile", inverse_of: :week_in_leave_file
    permit_params :week_in_compensatory_file_id

    # 週外振替
    belongs_to :week_out_compensatory_file, class_name: "Gws::Affair::OvertimeFile", inverse_of: :week_out_leave_file
    permit_params :week_out_compensatory_file_id

    # 代休振替
    belongs_to :holiday_compensatory_file, class_name: "Gws::Affair::OvertimeFile", inverse_of: :holiday_compensatory_leave_file
    permit_params :holiday_compensatory_file_id
  end

  private

  def validate_compensatory_file
    if leave_type != "week_in_compensatory_leave"
      self.week_in_compensatory_file_id = nil
    end
    if leave_type != "week_out_compensatory_leave"
      self.week_out_compensatory_file_id = nil
    end
    if leave_type != "holiday_compensatory_leave"
      self.holiday_compensatory_file_id = nil
    end
  end

  def validate_week_in_compensatory_file
    if week_in_compensatory_file.workflow_state != "approve"
      errors.add :week_in_compensatory_file_id, :not_approved
      return
    end

    file_ids = self.class.where(workflow_state: "approve", :id.ne => id).
      pluck(:week_in_compensatory_file_id)

    if file_ids.include?(week_in_compensatory_file_id)
      errors.add :week_in_compensatory_file_id, :use_in_other_leave_file
    end
  end

  def validate_week_out_compensatory_file
    if week_out_compensatory_file.workflow_state != "approve"
      errors.add :week_out_compensatory_file_id, :not_approved
      return
    end

    file_ids = self.class.where(workflow_state: "approve", :id.ne => id).
      pluck(:week_out_compensatory_file_id)

    if file_ids.include?(week_out_compensatory_file_id)
      errors.add :week_out_compensatory_file_id, :use_in_other_leave_file
    end
  end

  def validate_holiday_compensatory_file
    if holiday_compensatory_file.workflow_state != "approve"
      errors.add :holiday_compensatory_file_id, :not_approved
      return
    end

    file_ids = self.class.where(workflow_state: "approve", :id.ne => id).
      pluck(:holiday_compensatory_file_id)

    if file_ids.include?(holiday_compensatory_file_id)
      errors.add :holiday_compensatory_file_id, :use_in_other_leave_file
    end
  end

  def reset_overtime_compensatory
    [
      week_in_compensatory_file,
      week_out_compensatory_file,
      holiday_compensatory_file
    ].each do |file|
      next if file.nil?
      next if file.destroyed?
      file.reset_compensatory
      file.save # 時間外結果確定済みの場合保存に失敗する
    end
  end
end
