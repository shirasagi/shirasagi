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
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Board::BrowsingState

  readable_setting_include_custom_groups
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
    return Gws::User.none if categories.blank?

    conds = []
    conds << { id: { '$in' => categories.pluck(:subscribed_member_ids).flatten } }
    conds << { group_ids: { '$in' => categories.pluck(:subscribed_group_ids).flatten } }

    if Gws::Board::Category.subscription_setting_included_custom_groups?
      custom_gropus = Gws::CustomGroup.in(id: categories.pluck(:subscribed_custom_group_ids))
      conds << { id: { '$in' => custom_gropus.pluck(:member_ids).flatten } }
    end

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
