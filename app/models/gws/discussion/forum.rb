class Gws::Discussion::Forum
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  #include SS::Addon::Markdown
  #include Gws::Addon::File
  include Gws::Addon::Discussion::Release
  include Gws::Addon::Discussion::NotifySetting
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::Discussion::Quota
  include Gws::Addon::History

  member_include_custom_groups

  #class_variable_set(:@@_member_ids_required, false)

  set_permission_name "gws_discussion_forums"

  def discussion_member_ids
    ids = []

    # group permission
    #ids = user_ids
    #groups.each do |g|
    #  g = Gws::Group.find(g.id)
    #  ids += g.users.pluck(:id)
    #end

    # member
    ids += member_ids
    member_custom_groups.each do |custom_group|
      ids += custom_group.member_ids
    end

    ids.uniq
  end

  def discussion_members
    Gws::User.in(id: discussion_member_ids)
  end

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
