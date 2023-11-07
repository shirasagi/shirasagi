class Workflow::Mailer < ApplicationMailer
  def request_mail(args)
    @from_user = SS::User.find(args[:f_uid]) rescue nil
    @to_user   = SS::User.find(args[:t_uid]) rescue nil
    @agent_user = SS::User.find(args[:agent_uid]) rescue nil
    @site      = args[:site]
    @page      = args[:page]
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{@page.name} - #{@site.name}"
    @url       = make_full_url(args[:url])
    @comment   = args[:comment]

    from_email = format_email(@from_user) || site_sender(@site) || Cms::DEFAULT_SENDER_ADDRESS
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email, message_id: Cms.generate_message_id(@site)
  end

  def self.send_request_mails(args)
    args = args.dup
    Array(args.delete(:t_uids)).flatten.compact.uniq.each do |t_uid|
      args[:t_uid] = t_uid

      m = self.request_mail(args)
      m.deliver_now if m
    end
  end

  def approve_mail(args)
    @from_user = SS::User.find(args[:f_uid]) rescue nil
    @to_user   = SS::User.find(args[:t_uid]) rescue nil
    @site      = args[:site]
    @page      = args[:page]
    @subject   = "[#{I18n.t('workflow.mail.subject.approve')}]#{@page.name} - #{@site.name}"
    @url       = make_full_url(args[:url])

    from_email = format_email(@from_user) || site_sender(@site) || Cms::DEFAULT_SENDER_ADDRESS
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email, message_id: Cms.generate_message_id(@site)
  end

  def self.send_approve_mails(args)
    args = args.dup
    Array(args.delete(:t_uids)).flatten.compact.uniq.each do |t_uid|
      args[:t_uid] = t_uid

      m = self.approve_mail(args)
      m.deliver_now if m
    end
  end

  def remand_mail(args)
    @from_user = SS::User.find(args[:f_uid]) rescue nil
    @to_user   = SS::User.find(args[:t_uid]) rescue nil
    @site      = args[:site]
    @page      = args[:page]
    @subject   = "[#{I18n.t('workflow.mail.subject.remand')}]#{@page.name} - #{@site.name}"
    @url       = make_full_url(args[:url])
    @comment   = args[:comment]

    from_email = format_email(@from_user) || site_sender(@site) || Cms::DEFAULT_SENDER_ADDRESS
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email, message_id: Cms.generate_message_id(@site)
  end

  def self.send_remand_mails(args)
    args = args.dup
    Array(args.delete(:t_uids)).flatten.compact.uniq.each do |t_uid|
      args[:t_uid] = t_uid

      m = self.remand_mail(args)
      m.deliver_now if m
    end
  end

  def remind_mail(site:, page:, user:)
    @from_user = page.workflow_user
    @to_user   = user
    from_email = format_email(@from_user) || site_sender(site) || Cms::DEFAULT_SENDER_ADDRESS
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    @site = site
    @page = page
    mail from: from_email, to: to_email, message_id: Cms.generate_message_id(site)
  end

  private

  def format_email(user)
    return nil if user.blank? || user.email.blank?

    if user.name.present?
      "#{user.name} <#{user.email}>"
    else
      user.email
    end
  end

  def site_sender(site)
    return if site.blank?
    site.sender_address
  end

  def make_full_url(url)
    ::Addressable::URI.join(@site.mypage_full_url, url).to_s
  end
end
