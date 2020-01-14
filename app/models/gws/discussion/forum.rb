class Gws::Discussion::Forum
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  #include SS::Addon::Markdown
  #include Gws::Addon::File
  include Gws::Addon::Discussion::Release
  include Gws::Addon::Memo::NotifySetting
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::Discussion::Quota
  include Gws::Addon::History

  member_include_custom_groups

  #class_variable_set(:@@_member_ids_required, false)

  set_permission_name "gws_discussion_forums"

  def discussion_member_ids
    overall_members.pluck(:id)
  end
  deprecate discussion_member_ids: "discussion_member_ids is deprecated. use `#overall_members.pluck(:id)' instead"

  alias discussion_members overall_members
  deprecate discussion_members: "discussion_members is deprecated. use `#overall_members' instead"

  def save_main_topic
    main_topic = Gws::Discussion::Topic.new
    main_topic.forum_id = id
    main_topic.parent_id = id

    main_topic.main_topic = "enabled"
    main_topic.name = I18n.t("gws/discussion.main_topic.name")
    main_topic.text = I18n.t("gws/discussion.main_topic.text", name: name)
    main_topic.text_type = "text"

    main_topic.contributor_model = contributor_model
    main_topic.contributor_id = contributor_id
    main_topic.contributor_name = contributor_name

    main_topic.user_ids = user_ids
    main_topic.group_ids = group_ids
    main_topic.user_id = user_id
    main_topic.site_id = site_id

    main_topic.save!
  end
end
