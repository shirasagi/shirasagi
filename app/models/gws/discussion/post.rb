class Gws::Discussion::Post
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  #include Gws::Addon::Discussion::Release
  #include Gws::Addon::Discussion::ReadableSetting
  include Gws::Addon::Discussion::GroupPermission
  include Gws::Addon::History

  validates :text, presence: true

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::BoardPostJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::BoardPostJob.callback
end
