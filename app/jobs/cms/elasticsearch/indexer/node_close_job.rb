class Cms::Elasticsearch::Indexer::NodeCloseJob < Cms::ApplicationJob
  def perform
    criteria = Cms::Page.site(site).
      where(filename: /^#{::Regexp.escape(node.filename)}\//)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site).
          perform_now(action: 'delete', id: item.id.to_s)
      end
    end
    Cms::PageIndexQueue.site(site).in(id: all_ids).where(action: 'release').destroy_all
  end
end
