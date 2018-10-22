class Gws::Discussion::Post
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  #include Gws::Addon::Discussion::NotifySetting
  #include Gws::Addon::Discussion::Release
  #include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::Discussion::Quota
  include Gws::Addon::History

  set_permission_name "gws_discussion_posts"

  validates :text, presence: true

  def save_notify_message(site, user)
    return unless site.notify_model?(self)

    f = Gws::Discussion::Forum.find(forum.id)
    return if f.deleted?
    return unless f.public?
    return unless f.notify_enabled?

    notify_member_ids = f.discussion_member_ids - [user.id]
    notify_member_ids.select!{|user_id| Gws::User.find(user_id).use_notice?(self)}
    return if notify_member_ids.blank?

    url = Rails.application.routes.url_helpers.gws_discussion_forum_topic_comments_path(forum_id: forum.id, topic_id: topic.id, site: @cur_site.id, category: '-', mode: '-')

    item = Gws::Memo::Notice.new
    item.cur_site = site
    item.cur_user = user
    item.member_ids = notify_member_ids
    item.subject = I18n.t("gws/discussion.notify_message.post.subject", forum_name: forum.name, topic_name: topic.name)
    item.format = "text"
    item.text = I18n.t("gws/discussion.notify_message.post.text", topic_name: topic.name, text: url)
    item.send_date = Time.zone.now

    # set topic
    item.reply_item_id = topic.id
    item.reply_model = topic.reference_model
    item.reply_module = "discussion"
    item.save!

    to_users = notify_member_ids.map{|user_id| Gws::User.find(user_id)}
    Gws::Memo::Mailer.notice_mail(item, to_users, self).try(:deliver_now)
  end
end
