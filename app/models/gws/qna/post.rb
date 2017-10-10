# "Post" class for BBS. It represents "comment" models.
class Gws::Qna::Post
  include Gws::Referenceable
  include Gws::Qna::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Qna::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::QnaPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::QnaPostJob.callback
end
