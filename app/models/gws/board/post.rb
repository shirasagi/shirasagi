# "Post" class for BBS. It represents "comment" models.
class Gws::Board::Post
  include Gws::Referenceable
  include Gws::Board::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Board::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::BoardPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::BoardPostJob.callback

  def subscribed_users
    topic.subscribed_users
  end
end
