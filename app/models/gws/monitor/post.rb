class Gws::Monitor::Post
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Monitor::Category

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback

  delegate :subscribed_users, to: :topic

  # gws/file addon support
  def state
    topic.try(:state)
  end

  # gws/file addon support
  def state_changed?
    false
  end
end
