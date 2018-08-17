class Workflow::Mailer < ActionMailer::Base
  def request_mail(args)
    @from_user = SS::User.find(args[:f_uid]) rescue nil
    @to_user   = SS::User.find(args[:t_uid]) rescue nil
    @agent_user = SS::User.find(args[:agent_uid]) rescue nil
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]
    @comment   = args[:comment]
    @site      = args[:site]

    from_email = format_email(@from_user) || site_sender(@site) || system_sender
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
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
    @subject   = "[#{I18n.t('workflow.mail.subject.approve')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]

    from_email = format_email(@from_user) || site_sender(@site) || system_sender
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
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
    @subject   = "[#{I18n.t('workflow.mail.subject.remand')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]
    @comment   = args[:comment]

    from_email = format_email(@from_user) || site_sender(@site) || system_sender
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
  end

  def self.send_remand_mails(args)
    args = args.dup
    Array(args.delete(:t_uids)).flatten.compact.uniq.each do |t_uid|
      args[:t_uid] = t_uid

      m = self.remand_mail(args)
      m.deliver_now if m
    end
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
    return if site.blank? || site.sender_email.blank?

    if site.sender_name.present?
      "#{site.sender_name} <#{site.sender_email}>"
    else
      site.sender_email
    end
  end

  def system_sender
    SS.config.mail.default_from
  end
end
