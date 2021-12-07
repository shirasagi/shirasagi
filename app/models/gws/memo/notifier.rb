class Gws::Memo::Notifier
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_group, :cur_user, :to_users, :item, :item_title, :item_text, :subject, :text, :action

  class << self
    def deliver!(opts)
      new(opts).deliver!
    end

    def deliver_workflow_request!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)

      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user) || cur_user
      agent = item.try(:workflow_agent)

      title = I18n.t("gws_notification.gws/workflow/file.request", name: item.name)

      text = []
      text << "#{from.name}さん#{agent ? "（代理: #{agent.name}さん）" : ""}より次の記事について承認依頼が届きました。"
      text << "承認作業を行ってください。"
      text << ""
      text << "- タイトル"
      text << "  #{item.name}"
      text << ""
      text << "- 申請者"
      text << "  #{from.name}"
      if agent
        text << "  （代理: #{agent.name}）"
      end
      text << ""
      if comment.present?
        text << "- 申請者コメント"
        text << "  #{comment}"
        text << ""
      end
      text << "- URL"
      text << "  #{url}"

      opts[:item_title] = title
      opts[:item_text] = url

      new(opts).deliver!
    end

    def deliver_workflow_approve!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)

      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      item = opts[:item]
      from = item.try(:workflow_user)
      agent = item.try(:workflow_agent)

      title = I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)

      text = []
      text << "次の申請が承認されました。"
      text << ""
      text << "- タイトル"
      text << "  #{item.name}"
      text << ""
      text << "- 申請者"
      text << "  #{from.name}"
      if agent
        text << "  （代理: #{agent.name}）"
      end
      text << ""
      text << "- URL"
      text << "  #{url}"

      opts[:item_title] = title
      opts[:item_text] = url
      new(opts).deliver!
    end

    def deliver_workflow_remand!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)

      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user)
      agent = item.try(:workflow_agent)

      title = I18n.t("gws_notification.gws/workflow/file.remand", name: item.name)

      text = []
      text << "#{cur_user.name}さんより次の申請について承認依頼が差し戻されました。"
      text << "適宜修正を行い、再度承認依頼を行ってください。"
      text << ""
      text << "- タイトル"
      text << "  #{item.name}"
      text << ""
      text << "- 申請者"
      text << "  #{from.name}"
      if agent
        text << "  （代理: #{agent.name}）"
      end
      text << ""
      if comment.present?
        text << "- 差し戻しコメント"
        text << "  #{comment}"
        text << ""
      end
      text << "- URL"
      text << "  #{url}"

      opts[:item_title] = title
      opts[:item_text] = url

      new(opts).deliver!
    rescue => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise
    end

    def deliver_workflow_circulations!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)

      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      item = opts[:item]
      from = item.try(:workflow_user)
      agent = item.try(:workflow_agent)

      title = I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)

      text = []
      text << "次の申請が承認されました。"
      text << "申請内容を確認してください。"
      text << ""
      text << "- タイトル"
      text << "  #{item.name}"
      text << ""
      text << "- 申請者"
      text << "  #{from.name}"
      if agent
        text << "  （代理: #{agent.name}）"
      end
      text << ""
      text << "- URL"
      text << "  #{url}"

      opts[:item_title] = title
      opts[:item_text] = url

      new(opts).deliver!
    end

    def deliver_workflow_comment!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)

      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      item = opts[:item]
      from = item.try(:workflow_user)
      agent = item.try(:workflow_agent)

      title = I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)

      text = []
      text << "次の申請にコメントがありました。"
      text << "コメントの内容を確認してください。"
      text << ""
      text << "- タイトル"
      text << "  #{item.name}"
      text << ""
      text << "- 申請者"
      text << "  #{from.name}"
      if agent
        text << "  （代理: #{agent.name}）"
      end
      text << ""
      text << "- コメント"
      text << "  #{comment}"
      text << ""
      text << "- URL"
      text << "  #{url}"

      opts[:item_title] = title
      opts[:item_text] = url

      new(opts).deliver!
    end
  end

  def item_title
    @item_title ||= begin
      title = item.try(:topic).try(:name)
      title ||= item.try(:schedule).try(:name)
      title ||= item.try(:todo).try(:name)
      title ||= item.try(:_parent).try(:name)
      title ||= item.try(:name)
      title
    end
  end

  def item_text
    @item_text ||= begin
      text = item.try(:text)
      text ||= begin
        html = item.try(:html).presence
        ApplicationController.helpers.sanitize(html, tags: []) if html
      end
      text = text.truncate(60) if text
      text
    end
  end

  def deliver!
    cur_user.cur_site ||= cur_group
    now = Time.zone.now

    url = item_to_url(item)

    message = SS::Notification.new
    message.cur_group = cur_site
    message.cur_user = cur_user
    message.member_ids = to_users.pluck(:id)

    message.send_date = now

    message.subject = subject
    if action.present?
      message.subject ||= I18n.t("gws_notification.#{i18n_key}/#{action}.subject", name: item_title, default: nil)
    end
    message.subject ||= I18n.t("gws_notification.#{i18n_key}.subject", name: item_title, default: nil)
    message.subject ||= item_title
    message.format = 'text'
    message.url = text
    if action.present?
      message.url ||= I18n.t("gws_notification.#{i18n_key}/#{action}.text", name: item_title, text: url, default: nil)
    end
    message.url ||= I18n.t("gws_notification.#{i18n_key}.text", name: item_title, text: url, default: nil)
    message.url ||= item_text

    message.record_timestamps = false
    message.created = now
    message.updated = now

    message.save!

    mail = Gws::Memo::Mailer.notice_mail(message, to_users, item)
    mail.deliver_now if mail

    # item は操作対象の copy の場合がある。copy の場合 `set(...)` を呼び出しても DB が更新されないので、
    # 回りくどいようだが `where(id: item.id).set(...)` とする。
    item.class.where(id: item.id).set(notification_noticed_at: now.utc) if item.respond_to?(:notification_noticed_at)
  end

  private

  def item_to_url(item)
    class_name = item.class.name
    url_helper = Rails.application.routes.url_helpers

    if class_name.include?("Gws::Board")
      url = url_helper.gws_board_topic_path(id: id_for_url(item), site: cur_site.id, category: '-', mode: '-')
    elsif class_name.include?("Gws::Faq")
      url = url_helper.gws_faq_topic_path(id: id_for_url(item), site: cur_site.id, category: '-', mode: '-')
    elsif class_name.include?("Gws::Qna")
      anchor = item.topic_id ? "post-#{item.id}" : nil
      url = url_helper.gws_qna_topic_path(id: id_for_url(item), site: cur_site.id, category: '-', mode: '-', anchor: anchor)
    elsif class_name.include?("Gws::Schedule::Todo")
      todo = item.try(:todo) || item
      if todo.try(:in_discussion_forum) && todo.try(:discussion_forum)
        url = url_helper.gws_discussion_forum_todo_path(
          id: todo.id, site: cur_site.id, mode: "-", forum_id: todo.discussion_forum)
      else
        url = url_helper.gws_schedule_todo_readable_path(
          id: todo.id, site: cur_site.id, category: Gws::Schedule::TodoCategory::ALL.id)
      end
    elsif class_name.include?("Gws::Schedule")
      url = url_helper.gws_schedule_plan_path(id: id_for_url(item), site: cur_site.id)
    elsif class_name.include?("Gws::Monitor")
      return unless item.state == "public"

      id = id_for_url(item)
      url = url_helper.gws_monitor_topic_path(id: id, site: cur_site.id, category: '-', mode: '-')
      deliver_monitor(id)
    else
      url = ''
    end

    url
  end

  def id_for_url(item)
    if item.try(:topic).present?
      id = item.topic.id
    elsif item.try(:_parent).present?
      id = item._parent.id
    elsif item.try(:parent).present?
      id = item.parent.id
    elsif item.try(:schedule).present?
      id = item.schedule.id
    elsif item.try(:todo).present?
      todo = item.todo
    else
      id = item.id
    end

    id
  end

  def deliver_monitor(monitor_id)
    topic = Gws::Monitor::Topic.find(monitor_id)
    to_members = Gws::User.in(group_ids: Gws::Group.in(id: topic.attend_group_ids).pluck(:id)).pluck(:id)
    to_members -= [cur_user.id]
    to_members.select! { |user_id| Gws::User.find(user_id).use_notice?(item) }
    return if to_members.blank?

    self.to_users = to_members.map { |user_id| Gws::User.find(user_id) }
  end

  def i18n_key
    @i18n_key ||= item.class.model_name.i18n_key
  end
end
