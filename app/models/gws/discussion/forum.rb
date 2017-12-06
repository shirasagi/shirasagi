class Gws::Discussion::Forum
  include Gws::Referenceable
  include Gws::Discussion::Postable
  #include Gws::Addon::Contributor
  #include SS::Addon::Markdown
  #include Gws::Addon::File
  include Gws::Addon::Discussion::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::Discussion::GroupPermission
  include Gws::Addon::History

  readable_setting_include_custom_groups

  #after_save :save_descendants_setting
  #validates :text, presence: true

  def save_main_topic
    main_topic = Gws::Discussion::Topic.new
    main_topic.forum_id = id
    main_topic.parent_id = id

    main_topic.main_topic = "enabled"
    main_topic.name = "メインスレッド"
    main_topic.text= "#{name}のメインスレッドです。"
    main_topic.text_type = "text"

    #main_topic.contributor_model = contributor_model
    #main_topic.contributor_id = contributor_id
    #main_topic.contributor_name = contributor_name

    main_topic.user_ids = user_ids
    main_topic.custom_group_ids = custom_group_ids
    main_topic.group_ids = group_ids
    main_topic.user_id = user_id
    main_topic.site_id = site_id

    main_topic.save!
  end

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def discussion_members
    ids = user_ids
    groups.each do |g|
      ids += g.users.pluck(:id)
    end

    ids += readable_member_ids
    readable_groups.each do |g|
      ids += g.users.pluck(:id)
    end

    readable_custom_groups.each do |custom_group|
      ids += custom_group.readable_member_ids
    end

    Gws::User.in(id: ids.uniq)
  end

  def currect_readable?
    discussion_members.each do |u|
      p [u.id, u.name, readable?(u)]
    end

    p "---"

    Gws::User.nin(id: discussion_members.pluck(:id)).each do |u|
      p [u.id, u.name, readable?(u)]
    end
  end

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback
end
