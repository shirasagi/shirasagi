# "Post" class for BBS. It represents "topic" models.
class Gws::Board::Topic
  include Gws::Referenceable
  include Gws::Board::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Link
  include Gws::Board::DescendantsFileInfo
  include Gws::Addon::Board::Category
  include Gws::Addon::Board::NotifySetting
  include SS::Addon::Release
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Board::BrowsingState

  member_include_custom_groups
  member_ids_optional
  readable_setting_include_custom_groups
  no_needs_read_permission_to_read
  permission_include_custom_groups
  hide_released_field

  validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def subscribed_users
    return Gws::User.none if new_record?

    conds = []
    conds << { id: { '$in' => members.active.pluck(:id) } } if members.active.present?
    conds << { group_ids: { '$in' => member_groups.active.pluck(:id) } } if member_groups.active.present?
    if member_custom_groups.present?
      ids = member_custom_groups.to_a.map { |custom_group| custom_group.overall_members.active.pluck(:id) }.flatten.uniq
      conds << { id: { '$in' => ids } } if ids.present?
    end
    if categories.present?
      conds << { id: { '$in' => categories.pluck(:subscribed_member_ids).flatten } }
      conds << { group_ids: { '$in' => categories.pluck(:subscribed_group_ids).flatten } }
    end
    return Gws::User.none if conds.blank?

    Gws::User.where('$and' => [ { '$or' => conds } ])
  end

  private

  def set_descendants_updated_with_released
    if descendants_updated.present?
      self.descendants_updated = released if descendants_updated < released
    else
      self.descendants_updated = released
    end
  end
end
