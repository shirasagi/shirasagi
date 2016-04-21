# "Post" class for BBS. It represents "topic" models.
class Gws::Board::Topic
  include Gws::Referenceable
  include Gws::Board::Postable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Board::DescendantsFileInfo
  include Gws::Addon::Board::Category
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
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
