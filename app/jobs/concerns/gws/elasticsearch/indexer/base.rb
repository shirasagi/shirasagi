module Gws::Elasticsearch::Indexer::Base
  extend ActiveSupport::Concern

  included do
    cattr_accessor :model
  end

  module ClassMethods
    def callback
      self
    end

    def around_save(item)
      site = item.site
      before_file_ids = collect_file_ids_was_for_save(item)

      ret = yield
      return ret unless site.try(:menu_elasticsearch_visible?)

      after_file_ids = collect_file_ids_for_save(item)
      remove_file_ids = before_file_ids - after_file_ids

      if item.deleted.present?
        # soft deleted
        job = self.bind(site_id: site)
        job.perform_later(action: 'delete', id: item.id.to_s, remove_file_ids: (before_file_ids | after_file_ids).map(&:to_s))
        return ret
      end

      job = self.bind(site_id: site)
      job.perform_later(
        action: 'index', id: item.id.to_s, remove_file_ids: remove_file_ids.map(&:to_s)
      )

      ret
    end

    def around_destroy(item)
      site = item.site
      id = item.id
      file_ids = collect_file_ids_for_destroy(item)

      ret = yield

      if item.site.try(:menu_elasticsearch_visible?)
        job = self.bind(site_id: site)
        job.perform_later(action: 'delete', id: id.to_s, remove_file_ids: file_ids.map(&:to_s))
      end

      ret
    end

    def collect_file_ids_was_for_save(item)
      return [] if !item.respond_to?(:file_ids_was)
      [ item.file_ids_was ].flatten.compact
    end

    def collect_file_ids_for_save(item)
      return [] if !item.respond_to?(:file_ids)
      [ item.file_ids ].flatten.compact
    end

    def collect_file_ids_for_destroy(item)
      collect_file_ids_was_for_save(item)
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end

  def perform(options)
    options = options.dup
    action = options.delete(:action)

    Rails.logger.tagged(site.name) do
      self.send(action, options)
    end
  end

  private

  def url_helpers
    self.class.url_helpers
  end

  def each_item(criteria: nil, &_block)
    criteria ||= self.class.model.site(site).without_deleted

    case @original_id
    when :all
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        items = criteria.in(id: ids).to_a
        items.each do |item|
          Rails.logger.tagged("#{item.class.name}(#{item.id})") do
            yield item
          end
        end
      end
    else
      criteria ||= self.class.model.site(site).without_deleted
      item = criteria.where(id: @original_id).first
      if item
        Rails.logger.tagged("#{item.class.name}(#{item.id})") do
          yield item
        end
      end
    end
  end

  def item
    @item ||= model.find(@id)
  end

  def index_name
    @index ||= "g#{self.site.id}"
  end

  def index_type
    @index_type ||= model.collection_name
  end

  def index_item_id
    "#{index_type}-post-#{@id}"
  end

  def remove_file_ids
    @remove_file_ids ||= []
  end

  def index(options)
    @original_id = options[:id]
    @remove_file_ids = options[:remove_file_ids].presence || []

    es_client = self.site.elasticsearch_client
    return unless es_client

    enum_es_docs.each do |id, doc|
      index_params = {
        index: index_name, id: id, body: doc
      }
      index_params[:pipeline] = 'attachment' if id.start_with?('file-')
      with_rescue(Elasticsearch::Transport::Transport::ServerError) do
        es_client.index(index_params)
      end
    end

    if remove_file_ids.present?
      remove_file_ids.each do |id|
        with_rescue(Elasticsearch::Transport::Transport::ServerError) do
          es_client.delete(index: index_name, id: "file-#{id}")
        end
      end
    end
  end

  def delete(options)
    @id = options[:id]
    @remove_file_ids = options[:remove_file_ids].presence || []

    es_client = self.site.elasticsearch_client
    return unless es_client

    with_rescue(Elasticsearch::Transport::Transport::ServerError) do
      es_client.delete(index: index_name, id: index_item_id)
    end

    if remove_file_ids.present?
      remove_file_ids.uniq.each do |id|
        with_rescue(Elasticsearch::Transport::Transport::ServerError) do
          es_client.delete(index: index_name, id: "file-#{id}")
        end
      end
    end
  end

  def with_rescue(klass)
    yield
  rescue klass => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts_history(:warn, "#{e.class} (#{e.message})")
  end
end
