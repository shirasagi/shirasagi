class Workflow::ReminderJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "workflow:reminder"

  def perform(*args, **options)
    unless site.approve_remind_state_enabled?
      task.log "承認督促が無効です。"
      return
    end

    each_page do |page|
      send_workflow_reminder(page)
    end
  end

  private

  def now
    @now ||= Time.zone.now.change(usec: 0)
  end

  def each_page
    duration = SS::Duration.parse(site.approve_remind_later)

    criteria = Cms::Page.all.site(site).where(workflow_state: Workflow::Approver::WORKFLOW_STATE_REQUEST)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      pages = criteria.in(id: ids).to_a
      pages.each do |page|
        next unless Workflow.exceed_remind_limit?(duration, page, now: now)
        next if page.workflow_reminder_sent_at.present? && now <= page.workflow_reminder_sent_at + 1.day

        yield page
        page.set(workflow_reminder_sent_at: now.utc)
      end
    end
  end

  def send_workflow_reminder(page)
    target_user_ids = collect_target_users(page)
    return if target_user_ids.blank?

    target_users = Cms::User.all.in(id: target_user_ids).active.to_a
    return if target_users.blank?

    send_workflow_reminder_to_user(page, target_users)
  end

  def collect_target_users(page)
    level = page.workflow_current_level
    return if level.nil?

    page.workflow_approvers.select do |approver|
      approver[:level] == level && approver[:state] == Workflow::Approver::WORKFLOW_STATE_REQUEST
    end.pluck(:user_id)
  end

  def send_workflow_reminder_to_user(page, users)
    users_having_email = users.select { |user| user.email.present? }
    if users_having_email.present?
      users_having_email.each do |user|
        mail = Workflow::Mailer.remind_mail(site: site, page: page, user: user)
        mail.deliver_now if mail
      end
    end

    text = I18n.t(
      "workflow.notice.remind.text", from_name: page.workflow_user.try(:name), page_name: page.name,
      workflow_comment: page.workflow_comment, show_path: page.private_show_path
    )

    message = SS::Notification.new
    message.cur_user = page.workflow_user
    message.member_ids = users.map(&:id)
    message.send_date = now
    message.subject = I18n.t("workflow.notice.remind.subject", page_name: page.name, site_name: site.name)
    message.format = 'text'
    message.text = text
    message.save!

    task.log "#{users.map(&:long_name).join(",")}: 通知を送りました。"
  end
end
