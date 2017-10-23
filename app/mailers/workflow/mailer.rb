class Workflow::Mailer < ActionMailer::Base
  def request_mail(args)
    @from_user = SS::User.find(args[:f_uid])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]
    @comment   = args[:comment]
    @site      = args[:site]

    from_email = format_email(@from_user) || default_sender(@site)
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
  end

  def approve_mail(args)
    @from_user = SS::User.find(args[:f_uid])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.approve')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]

    from_email = format_email(@from_user) || default_sender(@site)
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
  end

  def remand_mail(args)
    @from_user = SS::User.find(args[:f_uid])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.remand')}]#{args[:page].name} - #{args[:site].name}"
    @page      = args[:page]
    @url       = args[:url]
    @comment   = args[:comment]

    from_email = format_email(@from_user) || default_sender(@site)
    to_email = format_email(@to_user)
    return nil if from_email.blank? || to_email.blank?

    mail from: from_email, to: to_email
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

  def default_sender(site)
  end
end
