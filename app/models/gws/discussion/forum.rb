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
  deprecate discussion_member_ids: "discussion_member_ids is deprecated. use `#overall_members.pluck(:id)' instead",
    deprecator: SS.deprecator

  alias discussion_members overall_members
  deprecate discussion_members: "discussion_members is deprecated. use `#overall_members' instead",
    deprecator: SS.deprecator

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

  def save_clone
    item = self.class.new
    item.attributes = self.attributes
    item.id = nil

    item.created = item.updated = Time.zone.now
    item.released = nil if respond_to?(:released)
    item.state = "closed" if item.depth == 1

    item.descendants_updated = nil
    item.skip_descendants_updated = true

    item.save!

    ids = children.order(id: 1).pluck(:id)
    ids.each do |id|
      child = Gws::Discussion::Topic.find(id) rescue nil
      next if child.nil?
      child.save_clone(item)
    end

    item
  end

  class << self
    def search(params = {})
      criteria = where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
