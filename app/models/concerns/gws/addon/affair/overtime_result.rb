module Gws::Addon::Affair::OvertimeResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_results

    embeds_one :result, class_name: "Gws::Affair::OvertimeResult"
    field :result_created, type: DateTime
    field :result_updated, type: DateTime
    field :result_closed, type: DateTime

    permit_params in_results: {}
    validate :validate_result_closed
  end

  def save_results
    return if in_results.blank?

    now = Time.zone.now
    in_results.each do |id, result|
      next if result["start_at_date"].blank? || result["start_at_hour"].blank? || result["start_at_minute"].blank?
      next if result["end_at_date"].blank? || result["end_at_hour"].blank? || result["end_at_minute"].blank?

      start_at = Time.zone.parse("#{result["start_at_date"]} #{result["start_at_hour"]}:#{result["start_at_minute"]}")
      end_at = Time.zone.parse("#{result["end_at_date"]} #{result["end_at_hour"]}:#{result["end_at_minute"]}")

      break_time_minute = 0
      break1_start_at = nil
      break1_end_at = nil
      break2_start_at = nil
      break2_end_at = nil

      if result["break1_start_at_date"].present? && result["break1_start_at_hour"].present? && result["break1_start_at_minute"].present? &&
         result["break1_end_at_date"].present? && result["break1_end_at_hour"].present? && result["break1_end_at_minute"].present?
        break1_start_at = Time.zone.parse("#{result["break1_start_at_date"]} #{result["break1_start_at_hour"]}:#{result["break1_start_at_minute"]}")
        break1_end_at = Time.zone.parse("#{result["break1_end_at_date"]} #{result["break1_end_at_hour"]}:#{result["break1_end_at_minute"]}")
        _, m = Gws::Affair::Utils.time_range_minutes((start_at..end_at), (break1_start_at..break1_end_at))
        break_time_minute += m
      end

      if result["break2_start_at_date"].present? && result["break2_start_at_hour"].present? && result["break2_start_at_minute"].present? &&
          result["break2_end_at_date"].present? && result["break2_end_at_hour"].present? && result["break2_end_at_minute"].present?
        break2_start_at = Time.zone.parse("#{result["break2_start_at_date"]} #{result["break2_start_at_hour"]}:#{result["break2_start_at_minute"]}")
        break2_end_at = Time.zone.parse("#{result["break2_end_at_date"]} #{result["break2_end_at_hour"]}:#{result["break2_end_at_minute"]}")
        _, m = Gws::Affair::Utils.time_range_minutes((start_at..end_at), (break2_start_at..break2_end_at))
        break_time_minute += m
      end

      file = self.class.find(id)

      item = Gws::Affair::OvertimeResult.new
      item.date = file.date
      item.start_at = start_at
      item.end_at = end_at

      item.break1_start_at = break1_start_at
      item.break1_end_at = break1_end_at
      item.break2_start_at = break2_start_at
      item.break2_end_at = break2_end_at

      item.break_time_minute = break_time_minute

      file.result = item
      file.result_created ||= now
      file.result_updated = now
      file.save
    end

    save_edit_result_message

    true
  end

  def validate_result_closed
    return if !result_closed?
    errors.add :base, "時間外結果確認済みのため更新できません。"
  end

  def result_closed?
    result_closed.present?
  end

  def result_closeable(user)
    workflow_approvers.to_a.map { |approver| approver[:user_id] }.include?(user.id)
  end

  def result_notify_member_ids
    member_ids = workflow_approvers.to_a.map { |approver| approver[:user_id] }
    member_ids += workflow_circulations.to_a.map { |approver| approver[:user_id] }
    member_ids += [target_user_id]
    member_ids
  end

  def close_result
    result_closed_at = Time.zone.now
    self.set(result_closed: result_closed_at)
    day_results.each do |item|
      item.set(result_closed: result_closed_at)
    end
    save_close_result_message
    true
  end

  def save_edit_result_message
    url = Rails.application.routes.url_helpers.gws_affair_overtime_file_path(
      site: site.id, state: "all", id: id
    )
    member_ids = result_notify_member_ids
    member_ids -= [cur_user.id] if cur_user

    item = SS::Notification.new
    item.cur_group = site
    item.cur_user = user
    item.member_ids = member_ids
    item.subject = "[時間外申請]「#{name}」の結果が入力されました。"
    item.format = "text"
    item.url = url
    item.send_date = Time.zone.now
    item.save
  end

  def save_close_result_message
    url = Rails.application.routes.url_helpers.gws_affair_overtime_file_path(
      site: site.id, state: "all", id: id
    )
    member_ids = result_notify_member_ids
    member_ids -= [cur_user.id] if cur_user

    item = SS::Notification.new
    item.cur_group = site
    item.cur_user = user
    item.member_ids = member_ids
    item.subject = "[時間外申請]「#{name}」の結果が確定されました。"
    item.format = "text"
    item.url = url
    item.send_date = Time.zone.now
    item.save
  end
end
