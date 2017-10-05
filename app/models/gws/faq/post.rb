# "Post" class for BBS. It represents "comment" models.
class Gws::Faq::Post
  include Gws::Referenceable
  include Gws::Faq::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Faq::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::FaqPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::FaqPostJob.callback
end
