class Gws::Discussion::Base
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Memo::NotifySetting
  include Gws::Addon::Discussion::Release
  include Gws::Addon::Member
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  #class_variable_set(:@@_member_ids_required, false)

  # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::DiscussionBaseJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::DiscussionBaseJob.callback
end
