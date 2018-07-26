class Opendata::Mailer < ActionMailer::Base
  def request_resource_mail(args)
    @from_user = Cms::Member.find(args[:m_id])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:item].name} - #{args[:site].name}"
    @item      = args[:item]
    @url       = args[:url]
    @resource_name = I18n.t("opendata.labels.#{@item.route.sub(/^.+?\//, "")}")

    mail from: @to_user.email, to: @to_user.email
  end

  def request_idea_comment_mail(args)
    @from_user = Cms::Member.find(args[:m_id])
    @to_user   = SS::User.find(args[:t_uid])
    @subject   = "[#{I18n.t('workflow.mail.subject.request')}]#{args[:idea].name} - #{args[:site].name}"
    @idea      = args[:idea]
    @comment   = args[:comment]
    @url       = args[:url]

    mail from: @to_user.email, to: @to_user.email
  end

  def export_datasets_mail(args)
    @to_user = SS::User.find(args[:t_uid])
    @subject = "#{I18n.t('opendata.export.subject')} - #{args[:site].name}"
    @link    = args[:link]

    mail from: @to_user.email, to: @to_user.email
  end

  def notify_dataset_update_plan(site, datasets)
    @subject = "更新予定のデータセット"
    @datasets = datasets
    @site = site

    mail from: site.sender_address, to: site.sender_address
  end
end
