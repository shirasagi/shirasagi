class Gws::Memo::Mailer < ActionMailer::Base
  def forward_mail(item, forward_emails)
    @item = item
    @cur_user = item.user
    @cur_site = item.site
    @to = @item.sorted_to_members.map { |item| "#{item.name} <#{item.email}>" }.join(", ")
    @cc = @item.sorted_cc_members.map { |item| "#{item.name} <#{item.email}>" }.join(", ")

    from = @cur_site.memo_email.presence || ActionMailer::Base.default[:from]
    subject = "[#{I18n.t("gws/memo/message.message")}]#{I18n.t("gws/memo/forward.subject")}:#{@cur_user.name}"

    @item.files.each do |file|
      attachments[file.name] = file.read
    end

    mail(from: from, bcc: forward_emails, subject: subject)
  end

  def notice_mail(notice, users, item)
    @notice = notice
    @item = item
    @users = users.select{|user| user.use_notice_email?(@item)}
    @cur_site = @item.try(:site) || @item.try(:cur_group) || @item.try(:_parent).try(:site)
    return unless @cur_site.allow_send_mail? || @users.present?
    from = ActionMailer::Base.default[:from]
    subject = @notice.subject
    body = I18n.t("gws_notification.#{i18n_key}.mail_text", subject: subject, text: page_url, default: item_text)
    mail(from: from, bcc: notice_address, subject: subject, body: body)
  end

  def notice_address
    @users.map(&:send_notice_mail_address).select(&:present?)
  end

  def i18n_key
    @item.class.model_name.i18n_key
  end

  def item_title
    title = @item.try(:topic).try(:name)
    title ||= @item.try(:schedule).try(:name)
    title ||= @item.try(:_parent).try(:name)
    title ||= @item.try(:name)
    title
  end

  def item_text
    text = @item.try(:text)
    text ||= begin
      html = @item.try(:html).presence
      ApplicationController.helpers.sanitize(html, tags: []) if html
    end
    text = text.truncate(60) if text
    text 
  end

  def page_url
    url_helper = Rails.application.routes.url_helpers
    url =  root_url(only_path: false)
    url = url.chop if url =~ /\/$/
    if @notice
      url += url_helper.gws_memo_notice_path(id: @notice.id, site: @cur_site.id)
    else
      id = @item.id
      class_name = @item.class.name
      if class_name.include?("Gws::Board")
        url += url_helper.gws_board_topic_path(id: id, site: @cur_site.id, category: '-', mode: '-')
      elsif class_name.include?("Gws::Faq")
        url += url_helper.gws_faq_topic_path(id: id, site: @cur_site.id, category: '-', mode: '-')
      elsif class_name.include?("Gws::Qna")
        url += url_helper.gws_qna_topic_path(id: id, site: @cur_site.id, category: '-', mode: '-')
      elsif class_name.include?("Gws::Schedule::Todo")
        url += url_helper.gws_schedule_todo_readable_path(id: id, site: @cur_site.id, category: '-', mode: '-')
      elsif class_name.include?("Gws::Schedule")
        url += url_helper.gws_schedule_plan_path(id: id, site: @cur_site.id, category: '-', mode: '-')
      else
        url = ''
      end
    end
  end
end

