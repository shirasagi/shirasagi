class Member::Mailer < ActionMailer::Base
  # 会員登録に対して確認メールを配信する。
  #
  # @param [Cms::Member] member
  def verification_mail(member)
    @member = member
    @node = Member::Node::Registration.first
    return if @node.blank?
    sender = "#{@node.sender_name} <#{@node.sender_email}>"

    mail from: sender, to: member.email
  end

  # パスワードの再設定メールを配信する。
  #
  # @params [Cms::Member] member
  def reset_password_mail(member)
    @member = member
    @node = Member::Node::Registration.first
    return if @node.blank?
    sender = "#{@node.sender_name} <#{@node.sender_email}>"

    mail from: sender, to: member.email
  end

  # グループ招待メールを配信する。
  #
  # @param [Cms::Member] member
  def group_invitation_mail(node, group, sender, recipent)
    from = "#{node.sender_name} <#{node.sender_email}>"
    to = recipent.email
    subject = node.group_invitation_subject
    body = Member::Renderer::GroupInvitation.render_template(
      node.group_invitation_template,
      node: node,
      group: group,
      sender: sender,
      recipent: recipent)
    return if body.blank?
    if node.group_invitation_signature.present?
      body << "\n"
      body << node.group_invitation_signature
    end
    body << "\n"

    mail from: from, to: to, subject: subject, body: body
  end

  # 会員招待メールを配信する。
  #
  # @param [Cms::Member] member
  def member_invitation_mail(node, group, sender, recipent)
    from = "#{node.sender_name} <#{node.sender_email}>"
    to = recipent.email
    subject = node.member_invitation_subject
    body = Member::Renderer::MemberInvitation.render_template(
      node.member_invitation_template,
      group: group,
      sender: sender,
      recipent: recipent)
    return if body.blank?
    if node.member_invitation_signature.present?
      body << "\n"
      body << node.member_invitation_signature
    end
    body << "\n"

    mail from: from, to: to, subject: subject, body: body
  end
end
