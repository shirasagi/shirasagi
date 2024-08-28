class Gws::Discussion::Topic
  include Gws::Discussion::Postable
  include Gws::Discussion::Searchable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  #include Gws::Addon::Discussion::NotifySetting
  #include Gws::Addon::Discussion::Release
  #include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::Discussion::Quota
  include Gws::Addon::History

  set_permission_name "gws_discussion_topics"
  member_ids_optional

  validates :text, presence: true

  def save_clone(new_forum)
    item = self.class.new
    item.attributes = self.attributes
    item.id = nil

    item.forum = new_forum
    item.parent = new_forum

    item.created = item.updated = Time.zone.now
    item.released = nil if respond_to?(:released)
    item.state = "closed" if item.depth == 1

    item.descendants_updated = nil
    item.skip_descendants_updated = true

    if respond_to?(:files)
      file_ids = []
      files.each do |f|
        file = SS::File.new
        file.attributes = f.attributes
        file.id = nil
        file.in_file = f.uploaded_file
        file.user_id = @cur_user.id if @cur_user

        file.save!
        file_ids << file.id
      end
      item.file_ids = file_ids
    end
    item.save!

    ids = children.order(id: 1).pluck(:id)
    ids.each do |id|
      child = Gws::Discussion::Post.find(id) rescue nil
      next if child.nil?
      child.save_clone(new_forum, item)
    end

    item
  end

  def save_notify_message(site, user)
    return unless site.notify_model?(self)

    f = Gws::Discussion::Forum.find(forum.id)
    return if f.deleted?
    return unless f.public?
    return unless f.notify_enabled?

    notify_member_ids = f.overall_members.pluck(:id) - [user.id]
    notify_member_ids.select! { |user_id| Gws::User.find(user_id).use_notice?(self) }
    return if notify_member_ids.blank?

    url_helpers = Rails.application.routes.url_helpers
    url = url_helpers.gws_discussion_forum_thread_comments_path(
      site: site, mode: '-', forum_id: forum, topic_id: self)

    item = SS::Notification.new
    item.cur_group = site
    item.cur_user = user
    item.member_ids = notify_member_ids
    item.subject = I18n.t("gws/discussion.notify_message.topic.subject", forum_name: forum.name, topic_name: name)
    item.format = "text"
    item.url = I18n.t("gws/discussion.notify_message.topic.text", topic_name: name, text: url)
    item.send_date = Time.zone.now

    # set topic
    item.reply_item_id = id
    item.reply_model = reference_model
    item.reply_module = "discussion"
    item.save!

    to_users = notify_member_ids.map { |user_id| Gws::User.find(user_id) }
    mail = Gws::Memo::Mailer.notice_mail(item, to_users, self)
    mail.deliver_now if mail
  end
end
