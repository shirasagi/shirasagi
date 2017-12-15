class Gws::Discussion::Base
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Discussion::NotifySetting
  include Gws::Addon::Discussion::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  readable_setting_include_custom_groups

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::DiscussionBaseJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::DiscussionBaseJob.callback
end
