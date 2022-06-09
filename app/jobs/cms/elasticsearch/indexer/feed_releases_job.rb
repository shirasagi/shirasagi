class Cms::Elasticsearch::Indexer::FeedReleasesJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:elasticsearch:indexer:feed_releases"

  def perform
    task.log "# #{site.name}"

    if site.elasticsearch_client.nil?
      task.log 'elasticsearch is not configured'
      return
    end

    ids = Cms::PageIndexQueue.site(site).order_by(created: -1).pluck(:id)
    del = []

    ids.each do |id|
      next if del.include?(id)
      item = Cms::PageIndexQueue.where(id: id).first
      next unless item

      task.log "- #{item.filename}"
      if site.elasticsearch_deny.include?(item.filename)
        item.destroy
        next
      end

      del += item.old_queues.pluck(:id)
      item.old_queues.destroy_all

      job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
      job.perform_now(action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
    end
  end
end
