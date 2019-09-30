class Gws::Affair::Notifier
  include ActiveModel::Model

  attr_accessor :item, :site, :group, :user, :to_users
  attr_accessor :subject, :text, :action

  class Mailer < ActionMailer::Base
  end

  def initialize(item)
    @item = item
    @site = item.site
    @group = item.site
    @user = item.user
    @model = item.class.to_s.tableize.singularize
  end

  def deliver_workflow_request(to_users, opts = {})
    @to_users = to_users
    @send_date = Time.zone.now

    url = opts[:url]
    comment = opts[:comment]

    @from_user = item.workflow_user
    @subject = I18n.t("gws_notification.#{@model}.request", name: item.name)

    @body = []
    @body << "#{@from_user.name}さんより承認依頼が届きました。"
    @body << "承認作業を行ってください。"
    @body << ""
    @body << "- タイトル"
    @body << "  #{@item.name}"
    @body << ""
    @body << "- 申請者"
    @body << "  #{@from_user.name}"
    @body << ""
    if comment.present?
      @body << "- 申請者コメント"
      @body << "  #{comment}"
      @body << ""
    end
    if url.present?
      @body << "- URL"
      @body << "  #{url}"
    end
    @body = @body.join("\n")

    save_ss_notification if notify_enabled?
    send_mail if mail_enabled?
  end

  def deliver_workflow_approve(to_users, opts = {})
    @to_users = to_users
    @send_date = Time.zone.now

    url = opts[:url]
    comment = opts[:comment]

    @from_user = item.workflow_user
    @subject = I18n.t("gws_notification.#{@model}.approve", name: item.name)

    @body = []
    @body << "次の申請が承認されました。"
    @body << ""
    @body << "- タイトル"
    @body << "  #{@item.name}"
    @body << ""
    @body << "- 申請者"
    @body << "  #{@from_user.name}"
    @body << ""
    if comment.present?
      @body << "- 承認コメント"
      @body << "  #{comment}"
      @body << ""
    end
    if url.present?
      @body << "- URL"
      @body << "  #{url}"
    end
    @body = @body.join("\n")

    save_ss_notification if notify_enabled?
    send_mail if mail_enabled?
  end

  def deliver_workflow_remand(to_users, opts = {})
    @to_users = to_users
    @send_date = Time.zone.now

    url = opts[:url]
    comment = opts[:comment]

    @from_user = item.workflow_user
    @subject = I18n.t("gws_notification.#{@model}.remand", name: item.name)

    @body = []
    @body << "承認依頼が差し戻されました。"
    @body << "適宜修正を行い、再度承認依頼を行ってください。"
    @body << ""
    @body << "- タイトル"
    @body << "  #{@item.name}"
    @body << ""
    @body << "- 申請者"
    @body << "  #{@from_user.name}"
    @body << ""
    if comment.present?
      @body << "- 差し戻しコメント"
      @body << "  #{comment}"
      @body << ""
    end
    if url.present?
      @body << "- URL"
      @body << "  #{url}"
    end
    @body = @body.join("\n")

    save_ss_notification if notify_enabled?
    send_mail if mail_enabled?
  end

  def deliver_workflow_circulations(to_users, opts = {})
    @to_users = to_users
    @send_date = Time.zone.now

    url = opts[:url]
    comment = opts[:comment]

    @from_user = item.workflow_user
    @subject = I18n.t("gws_notification.#{@model}.circular", name: item.name)

    @body = []
    @body << "次の申請が承認されました。"
    @body << "申請内容を確認してください。"
    @body << ""
    @body << "- タイトル"
    @body << "  #{@item.name}"
    @body << ""
    @body << "- 申請者"
    @body << "  #{@from_user.name}"
    @body << ""
    if comment.present?
      @body << "- 差し戻しコメント"
      @body << "  #{comment}"
      @body << ""
    end
    if url.present?
      @body << "- URL"
      @body << "  #{url}"
    end
    @body = @body.join("\n")

    save_ss_notification if notify_enabled?
    send_mail if mail_enabled?
  end

  def deliver_workflow_comment(to_users, opts = {})
    @to_users = to_users
    @send_date = Time.zone.now

    url = opts[:url]
    comment = opts[:comment]

    @from_user = item.workflow_user
    @subject = I18n.t("gws_notification.#{@model}.comment", name: item.name)

    @body = []
    @body << "次の申請にコメントがありました。"
    @body << "コメントの内容を確認してください。"
    @body << ""
    @body << "- タイトル"
    @body << "  #{@item.name}"
    @body << ""
    @body << "- 申請者"
    @body << "  #{@from_user.name}"
    @body << ""
    if comment.present?
      @body << "- コメント"
      @body << "  #{comment}"
      @body << ""
    end
    if url.present?
      @body << "- URL"
      @body << "  #{url}"
    end
    @body = @body.join("\n")

    save_ss_notification if notify_enabled?
    send_mail if mail_enabled?
  end

  def notify_enabled?
    @site.notify_model?(@item.class) && @user.use_notice?(@item)
  end

  def mail_enabled?
    @site.notify_model?(@item.class) && @site.allow_send_mail?
  end

  private

  def save_ss_notification
    return if @to_users.blank?

    message = SS::Notification.new
    message.cur_group = @site
    message.cur_user = @user
    message.member_ids = @to_users.pluck(:id)
    message.send_date = @send_date
    message.subject = @subject
    message.format = 'text'
    message.url = @item.private_show_path
    message.save!
  end

  def send_mail
    bcc = []
    @to_users.each do |user|
      next if !user.use_notice_email?(@item)
      email = user.send_notice_mail_addresses

      next if email.blank?
      next if !@site.email_domain_allowed?(email)

      bcc << email
    end
    return if bcc.blank?

    mail = SS::Mailer.new_message(from: @site.sender_address, bcc: bcc, subject: @subject, body: @body)

    begin
      mail.deliver_now
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end
  end
end
