class Opendata::Mailer < ApplicationMailer
  def request_resource_mail(args)
    @from_user = Cms::Member.find(args[:m_id])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:item].name} - #{args[:site].name}"
    @item      = args[:item]
    @url       = args[:url]
    @resource_name = I18n.t("opendata.labels.#{@item.route.sub(/^.+?\//, "")}")

    mail from: @to_user.email, to: @to_user.email, message_id: Cms.generate_message_id(args[:site])
  end

  def request_idea_comment_mail(args)
    @from_user = Cms::Member.find(args[:m_id])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:idea].name} - #{args[:site].name}"
    @idea      = args[:idea]
    @comment   = args[:comment]
    @url       = args[:url]

    mail from: @to_user.email, to: @to_user.email, message_id: Cms.generate_message_id(args[:site])
  end

  def export_datasets_mail(args)
    @to_user = SS::User.find(args[:t_uid])
    @subject = "#{I18n.t('opendata.export.subject')} - #{args[:site].name}"
    @link    = args[:link]

    mail from: @to_user.email, to: @to_user.email, message_id: Cms.generate_message_id(args[:site])
  end

  def notify_dataset_update_plan(site, datasets)
    @subject = I18n.t("opendata.notify_update_plan.subject")
    @datasets = datasets
    @site = site

    mail from: site.sender_address, to: site.sender_address, message_id: Cms.generate_message_id(site)
  end

  def notice_metadata_import_mail(importer, report)
    @importer = importer
    @report = report
    @subject = report.notice_subject
    @site = importer.site

    mail from: @site.sender_address, to: importer.notice_users.pluck(:email), subject: @subject,
      message_id: Cms.generate_message_id(@site)
  end
end
