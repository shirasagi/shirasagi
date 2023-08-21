# "Post" class for BBS. It represents "comment" models.
class Gws::Board::Post
  include Gws::Referenceable
  include Gws::Board::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Link
  include Gws::Board::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::BoardPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::BoardPostJob.callback

  delegate :subscribed_users, to: :topic

  after_create :clear_browsed

  private

  def clear_browsed
    if topic_id.blank?
      topic = self
    else
      topic = self.topic
      return if topic.blank?
    end

    topic = Gws::Board::Topic.find(topic.id) if !topic.is_a?(Gws::Board::Topic)
    topic.unset_browsed_except!(user)
  end
end
