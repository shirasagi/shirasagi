class Gws::Workflow2::ApproveService
  include ActiveModel::Model

  PERMIT_PARAMS = [ :comment, file_ids: SS::EMPTY_ARRAY ].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :type, :item, :ref, :comment, :file_ids

  validates :base, "gws/workflow2/approvable" => true
  validate :validate_item

  define_model_callbacks :approve

  def initialize(*args)
    super
    self.type = :approve
  end

  def call
    save_level = work_item.workflow_current_level
    if type == :pull_up
      work_item.pull_up_workflow_approver_state(cur_user, comment: comment, file_ids: file_ids)
    else
      work_item.approve_workflow_approver_state(cur_user, comment: comment, file_ids: file_ids)
    end

    if work_item.finish_workflow?
      work_item.approved = Time.zone.now
      work_item.workflow_state = Gws::Workflow::File::WORKFLOW_STATE_APPROVE
    end

    return false unless work_item.save

    current_level = work_item.workflow_current_level
    if !work_item.finish_workflow? && save_level != current_level
      # escalate workflow
      send_request
    end

    workflow_state = work_item.workflow_state
    if workflow_state == Gws::Workflow::File::WORKFLOW_STATE_APPROVE
      # finished workflow
      run_callbacks :approve do
        send_approve
        send_destination
        send_circulation
      end
    end

    return false if work_item.errors.present?

    self.item = work_item
    true
  end

  private

  def work_item
    @work_item ||= begin
      work_item = item.class.find(item.id)
      work_item.cur_site = cur_site if work_item.respond_to?(:cur_site=)
      work_item.site = cur_site if work_item.respond_to?(:site=)
      work_item.cur_user = cur_user if work_item.respond_to?(:cur_user=)
      work_item
    end
  end

  def validate_item
    if work_item.invalid?
      SS::Model.copy_errors(work_item, self)
      return false
    end

    true
  end

  # rubocop:disable Rails/Pluck
  def send_request
    current_level = work_item.workflow_current_level

    to_user_ids = work_item.workflow_approvers_at(current_level).map { |approver| approver[:user_id] }
    to_user_ids.compact!
    to_user_ids.uniq!
    to_user_ids.delete(cur_user.id)
    if to_user_ids.present?
      Gws::Memo::Notifier.deliver_workflow_request!(
        cur_site: cur_site, cur_group: cur_group, cur_user: work_item.workflow_user,
        to_users: Gws::User.in(id: to_user_ids).active, item: work_item, url: ref
      )
    end

    work_item.set_workflow_approver_state_to_request
    work_item.save
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
  # rubocop:enable Rails/Pluck

  def send_approve
    to_user_ids = [ work_item.workflow_user_id, work_item.workflow_agent_id ].compact - [ cur_user.id ]
    return if to_user_ids.blank?

    notify_user_ids = to_user_ids.uniq
    return if notify_user_ids.blank?

    Gws::Memo::Notifier.deliver_workflow_approve!(
      cur_site: cur_site, cur_group: cur_group, cur_user: cur_user,
      to_users: Gws::User.in(id: notify_user_ids).active, item: work_item, url: ref
    )
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  def send_destination
    to_users = work_item.workflow_destination_users
    return if to_users.blank?

    notify_users = to_users.site(cur_site).active.to_a.uniq
    return if notify_users.blank?

    Gws::Memo::Notifier.deliver_workflow_destination!(
      cur_site: cur_site, cur_group: cur_group, cur_user: work_item.workflow_user,
      to_users: notify_users, item: work_item, url: ref
    )
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  def send_circulation
    return unless work_item.move_workflow_circulation_next_step

    current_circulation_users = work_item.workflow_current_circulation_users.nin(id: cur_user.id).active
    if current_circulation_users.present?
      Gws::Memo::Notifier.deliver_workflow_circulations!(
        cur_site: cur_site, cur_group: cur_group, cur_user: work_item.workflow_user,
        to_users: current_circulation_users, item: work_item, url: ref
      )
    end

    work_item.save
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
end
