class Gws::Discussion::Topic
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  #include Gws::Addon::Discussion::Release
  #include Gws::Addon::Discussion::ReadableSetting
  include Gws::Addon::Discussion::GroupPermission
  include Gws::Addon::History

  #readable_setting_include_custom_groups

  #after_save :save_descendants_setting

  validates :text, presence: true

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::BoardTopicJob.callback
end
