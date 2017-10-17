# "Post" class for BBS. It represents "comment" models.
class Gws::Monitor::Post
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
end

