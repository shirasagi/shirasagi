class Member::Mailer < ApplicationMailer
  def notify_mail(member)
    @member = member
    @node = Member::Node::Registration.site(member.site).and_public.first
    return if @node.blank?
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: @node.notice_email, message_id: Cms.generate_message_id(@node.cur_site || @node.site)
  end

  # 会員登録に対して確認メールを配信する。
  #
  # @param [Cms::Member] member
  def verification_mail(member)
    @member = member
    @node = Member::Node::Registration.site(member.site).and_public.first
    return if @node.blank?
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: member.email, message_id: Cms.generate_message_id(@node.cur_site || @node.site)
  end

  # パスワードの再設定メールを配信する。
  #
  # @params [Cms::Member] member
  def reset_password_mail(member)
    @member = member
    @node = Member::Node::Registration.site(member.site).and_public.first
    return if @node.blank?
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: member.email, message_id: Cms.generate_message_id(@node.cur_site || @node.site)
  end

  # 登録完了通知メールを配信する。
  #
  # @params [Cms::Member] member
  def registration_completed_mail(member)
    @member = member
    @node = Member::Node::Registration.site(member.site).and_public.first
    return if @node.blank?
    sender = Cms.sender_address(@node, @node.cur_site || @node.site)

    mail from: sender, to: member.email, message_id: Cms.generate_message_id(@node.cur_site || @node.site)
  end

  # グループ招待メールを配信する。
  #
  # @param [Cms::Member] member
  def group_invitation_mail(node, group, sender, recipent)
    from = Cms.sender_address(node, node.cur_site || node.site)
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

    mail from: from, to: to, subject: subject, body: body, message_id: Cms.generate_message_id(node.cur_site || node.site)
  end

  # 会員招待メールを配信する。
  #
  # @param [Cms::Member] member
  def member_invitation_mail(node, group, sender, recipent)
    from = Cms.sender_address(node, node.cur_site || node.site)
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

    mail from: from, to: to, subject: subject, body: body, message_id: Cms.generate_message_id(node.cur_site || node.site)
  end
end
