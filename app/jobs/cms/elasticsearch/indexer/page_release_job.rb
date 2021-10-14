class Cms::Elasticsearch::Indexer::PageReleaseJob < Cms::ApplicationJob
  include Cms::Elasticsearch::Indexer::Base

  self.model = Cms::Page

  private

  def index_item_id
    queue.try(:filename) || item.filename
  end

  def queue
    @queue ||= Cms::PageIndexQueue.find(@queue_id) if @queue_id.present?
  end

  def index(options)
    @queue_id = options[:queue_id]
    super(options)
    queue.destroy if queue
  end

  def delete(options)
    @queue_id = options[:queue_id]
    super(options)
    queue.destroy if queue
  end

  def enum_es_docs
    Cms::Elasticsearch::PageConvertor.with_route(item, index_item_id: index_item_id).enum_es_docs
  end
end
