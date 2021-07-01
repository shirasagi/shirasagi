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
    Enumerator.new do |y|
      y << convert_to_doc
      item.files.each { |file| y << convert_file_to_doc(file) }
    end
  end

  def convert_to_doc
    doc = {}
    doc[:url] = item.url
    doc[:name] = item.name
    doc[:text] = item_text
    doc[:filename] = item.path
    doc[:state] = item.state

    doc[:categories] = item.categories.pluck(:name)
    doc[:category_ids] = item.category_ids
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:site_id] = item.site_id

    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ index_item_id, doc ]
  end

  def convert_file_to_doc(file)
    doc = {}
    doc[:url] = item.url
    doc[:name] = file.name
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size

    doc[:path] = item.path
    doc[:state] = item.state

    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def item_text
    if Fs.exists?(item.path)
      html = Fs.read(item.path)
    else
      html = item.html
    end
    config = SS.config.cms.elasticsearch
    site_search_marks = config['site-search-marks']
    if html =~ /<!--[^>]*?\s#{site_search_marks[0]}\s[^>]*?-->(.*)<!--[^>]*?\s#{site_search_marks[1]}\s[^>]*?-->/im
      html = $1
    elsif html =~ /<\s*body[^>]*>(.*)<\/\s*body\s*>/im
      html = $1
    end
    ApplicationController.helpers.sanitize(html.presence || '', tags: [])
  end
end
