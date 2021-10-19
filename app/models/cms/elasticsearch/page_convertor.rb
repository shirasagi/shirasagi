class Cms::Elasticsearch::PageConvertor
  attr_reader :item
  attr_writer :index_item_id

  def initialize(item, opts = {})
    @item = item
    @index_item_id = opts[:index_item_id]
  end

  def enum_es_docs
    Enumerator.new do |y|
      y << convert_to_doc
      convert_files_to_docs.each { |doc| y << doc }
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

    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    [ index_item_id, doc ]
  end

  def convert_files_to_docs
    docs = []
    item.attached_files.each do |file|
      # should include public file only?
      docs << convert_file_to_doc(file)
    end
    docs
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

  def index_item_id
    @index_item_id ||= "page-#{item.id}"
    @index_item_id
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

  class << self
    def with_route(item, opts = {})
      klass = "#{self.name}::#{item.route.classify.gsub("::", "")}".constantize rescue self
      convertor = klass.new(item)
      convertor.index_item_id = opts[:index_item_id] if opts[:index_item_id].present?
      convertor
    end
  end
end
