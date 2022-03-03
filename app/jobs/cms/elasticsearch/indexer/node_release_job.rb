class Cms::Elasticsearch::Indexer::NodeReleaseJob < Cms::ApplicationJob
  def perform
    criteria = Cms::Page.site(site).
      where(filename: /^#{::Regexp.escape(node.filename)}\//)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        next unless item.public_node?

        Cms::PageRelease.release(item)
      end
    end
  end
end
