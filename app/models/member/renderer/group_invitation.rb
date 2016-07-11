class Member::Renderer::GroupInvitation
  include ActiveModel::Model
  include SS::TemplateVariable

  attr_accessor :node, :group, :sender, :recipent

  template_variable_handler(:sender_name, :template_variable_handler_sender_name)
  template_variable_handler(:sender_email, :template_variable_handler_sender_email)
  template_variable_handler(:group_name, :template_variable_handler_group_name)
  template_variable_handler(:invitation_message, :template_variable_handler_invitation_message)
  template_variable_handler(:accept_url, :template_variable_handler_accept_url)
  template_variable_handler(:reject_url, :template_variable_handler_reject_url)

  private
    def template_variable_handler_sender_name(*_)
      sender.name
    end

    def template_variable_handler_sender_email(*_)
      sender.email
    end

    def template_variable_handler_group_name(*_)
      group.name
    end

    def template_variable_handler_invitation_message(*_)
      group.invitation_message
    end

    def template_variable_handler_accept_url(*_)
      "#{node.full_url}#{group.id}/accept"
    end

    def template_variable_handler_reject_url(*_)
      "#{node.full_url}#{group.id}/reject"
    end
end
