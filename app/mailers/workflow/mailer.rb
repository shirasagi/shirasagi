class Workflow::Mailer < ActionMailer::Base
  public
    def request_mail(args)
      @from_user = SS::User.find(args[:f_uid])
      @to_user   = SS::User.find(args[:t_uid])
      @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:page].name} - #{args[:site].name}"
      @page      = args[:page]
      @url       = args[:url]
      @comment   = args[:comment]

      mail from: @from_user.email, to: @to_user.email
    end

    def approve_mail(args)
      @from_user = SS::User.find(args[:f_uid])
      @to_user   = SS::User.find(args[:t_uid])
      @subject   = "[#{I18n.t('workflow.mail.subject.approve')}]#{args[:page].name} - #{args[:site].name}"
      @page      = args[:page]
      @url       = args[:url]

      mail from: @from_user.email, to: @to_user.email
    end

    def remand_mail(args)
      @from_user = SS::User.find(args[:f_uid])
      @to_user   = SS::User.find(args[:t_uid])
      @subject   = "[#{I18n.t('workflow.mail.subject.remand')}]#{args[:page].name} - #{args[:site].name}"
      @page      = args[:page]
      @url       = args[:url]
      @comment   = args[:comment]

      mail from: @from_user.email, to: @to_user.email
    end
end
