# "Post" class for BBS. It represents "topic" models.
class Gws::Faq::Topic
  include Gws::Referenceable
  include Gws::Faq::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Faq::DescendantsFileInfo
  include Gws::Addon::Faq::Category
  include SS::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Faq::BrowsingState

  readable_setting_include_custom_groups
  hide_released_field

  validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::FaqTopicJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::FaqTopicJob.callback

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      where({}).order_by(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      where({}).order_by(descendants_updated: key.end_with?('_asc') ? 1 : -1)
    else
      where({})
    end
  }

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def subscribed_users
    return Gws::User.none if new_record?
    return Gws::User.none if categories.blank?

    conds = []
    conds << { id: { '$in' => categories.pluck(:subscribed_member_ids).flatten } }
    conds << { group_ids: { '$in' => categories.pluck(:subscribed_group_ids).flatten } }

    if Gws::Faq::Category.subscription_setting_included_custom_groups?
      custom_gropus = Gws::CustomGroup.in(id: categories.pluck(:subscribed_custom_group_ids))
      conds << { id: { '$in' => custom_gropus.pluck(:member_ids).flatten } }
    end

    Gws::User.where('$and' => [ { '$or' => conds } ])
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
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
