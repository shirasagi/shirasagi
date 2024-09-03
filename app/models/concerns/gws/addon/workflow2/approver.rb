module Gws::Addon::Workflow2::Approver
  extend ActiveSupport::Concern
  extend SS::Addon
  include ::Workflow::Approver

  included do
    field :workflow_user_custom_data, type: Array
    field :workflow_agent_custom_data, type: Array
  end

  # override ::Workflow::Approver.apply_workflow?
  #
  # ::Workflow::Approver.apply_workflow? ではユーザーが read と approve の両方の権限を持っているかをチェックしているが、
  # これらの権限は承認者や回覧者から自動判定されるためチェックは不要。そして、approve 権限は削除したので、逆にチェックしても成功しない。
  # read と approve の権限チェックを削除することとする。
  def apply_workflow?(route)
    route.validate
    SS::Model.copy_errors(route, self) if route.errors.present?
    errors.empty?
  end

  # override ::Workflow::Approver.validate_workflow_approvers_role
  #
  # ::Workflow::Approver.validate_workflow_approvers_role ではユーザーが read と approve の両方の権限を持っているかをチェックしているが、
  # これらの権限は承認者や回覧者から自動判定されるためチェックは不要。そして、approve 権限は削除したので、逆にチェックしても成功しない。
  # read と approve の権限チェックを削除するため、メソッドの中身を空にする。
  def validate_workflow_approvers_role
  end

  # override ::Workflow::Approver.cancel_request
  #
  # ::Workflow::Approver.cancel_request では state をチェックしているが、
  # Gws::Workflow2::File には state はない（かつて存在していたが、存在していると逆に邪魔・不具合の温床となりそうなので削除）。
  # そこで、state のチェックをしないようにする
  def cancel_request
    return if workflow_state != "request"
    return if @cur_user.nil? || workflow_user.nil?
    return if @cur_user.id != workflow_user.id

    reset_workflow
    self.set(workflow_state: WORKFLOW_STATE_CANCELLED)
  end

  def update_workflow_user(site, user)
    if user.blank?
      self.workflow_user = nil
      self.workflow_user_id = nil
      self.workflow_user_custom_data = nil
      return
    end

    self.workflow_user = user

    custom_data = [
      { name: "name", value: user.name },
      { name: "uid", value: user.uid },
      { name: "email", value: user.email },
    ]
    user_data = ::Gws::UserFormData.site(site).user(user).order_by(id: 1, created: 1).first
    if user_data
      custom_data += user_data.column_values.to_a.map { |column_value| { name: column_value.name, value: column_value.value } }
    end

    if group = user.gws_main_group(site)
      custom_data += [
        { name: "name", value: group.name },
        { name: "section_name", value: group.section_name },
      ]
    end

    self.workflow_user_custom_data = custom_data
  end

  def update_workflow_agent(site, user)
    if user.blank?
      self.workflow_agent = nil
      self.workflow_agent_id = nil
      self.workflow_agent_custom_data = nil
      return
    end

    self.workflow_agent = user

    custom_data = [
      { name: "name", value: user.name },
      { name: "uid", value: user.uid },
      { name: "email", value: user.email },
    ]
    user_data = ::Gws::UserFormData.site(site).user(user).order_by(id: 1, created: 1).first
    if user_data
      custom_data += user_data.column_values.to_a.map { |column_value| { name: column_value.name, value: column_value.value } }
    end

    if group = user.gws_main_group(site)
      custom_data += [
        { name: "name", value: group.name },
        { name: "section_name", value: group.section_name },
      ]
    end
    self.workflow_agent_custom_data = custom_data
  end

  def not_yet_requested?
    workflow_state.blank?
  end
end
