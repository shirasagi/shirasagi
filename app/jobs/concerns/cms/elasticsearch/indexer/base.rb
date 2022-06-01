module Cms::Elasticsearch::Indexer::Base
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
      return ret if !item.site.try(:menu_elasticsearch_visible?)

      job = self.bind(site_id: site)
      job.perform_later(action: 'delete', id: id.to_s, remove_file_ids: file_ids.map(&:to_s))

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

    self.send(action, options)
  end

  private

  def url_helpers
    self.class.url_helpers
  end

  def item
    @item ||= model.find(@id)
  end

  def index_name
    @index ||= "s#{self.site.id}"
  end

  def index_type
    @index_type ||= '_doc'
  end

  def index_item_id
    "page-#{@id}"
  end

  def remove_file_ids
    @remove_file_ids ||= []
  end

  def index(options)
    @id = options[:id]
    @remove_file_ids = options[:remove_file_ids].presence || []

    es_client = self.site.elasticsearch_client
    return unless es_client

    enum_es_docs.each do |id, doc|
      index_params = {
        index: index_name, type: index_type, id: id, body: doc
      }
      index_params[:pipeline] = 'attachment' if id.start_with?('file-')
      with_rescue(Elasticsearch::Transport::Transport::ServerError) do
        es_client.index(index_params)
      end
    end

    if remove_file_ids.present?
      remove_file_ids.each do |id|
        with_rescue(Elasticsearch::Transport::Transport::ServerError) do
          es_client.delete(index: index_name, type: index_type, id: "file-#{id}")
        end
      end
    end
  end

  def delete(options)
    @id = options[:id]
    @remove_file_ids = options[:remove_file_ids].presence || []

    es_client = self.site.elasticsearch_client
    return unless es_client

    with_rescue(Elasticsearch::Transport::Transport::ServerError, severity: -1) do
      es_client.delete(index: index_name, type: index_type, id: index_item_id)
    end

    if remove_file_ids.present?
      remove_file_ids.uniq.each do |id|
        with_rescue(Elasticsearch::Transport::Transport::ServerError, severity: -1) do
          es_client.delete(index: index_name, type: index_type, id: "file-#{id}")
        end
      end
    end

    if @queue.present? && (page = @queue.page).present? && page.state == "closed"
      remove_all_files(page)
    end
  end

  def remove_all_files(page)
    file_ids = []

    file_id_collector = proc do |item|
      if item.respond_to?(:file_id) && item.file_id
        file_ids << item.file_id
      end
      if item.respond_to?(:thumb_id) && item.thumb_id
        file_ids << item.thumb_id
      end
      if item.respond_to?(:file_ids) && item.file_ids.present?
        file_ids += item.file_ids
      end
    end

    file_id_collector.call(page)
    if page.respond_to?(:column_values) && page.column_values.present?
      page.column_values.each do |column_value|
        file_id_collector.call(column_value)
      end
    end

    file_ids.compact!
    file_ids.uniq!
    return if file_ids.blank?

    es_client = self.site.elasticsearch_client
    file_ids.uniq.each do |id|
      with_rescue(Elasticsearch::Transport::Transport::ServerError, severity: -1) do
        es_client.delete(index: index_name, type: index_type, id: "file-#{id}")
      end
    end
  end

  def with_rescue(klass, severity: ::Logger::Severity::WARN)
    yield
  rescue klass => e
    # negative severity means 'suppress' or 'quiet'
    return if severity.numeric? && severity < 0
    Rails.logger.add(severity) { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
end
