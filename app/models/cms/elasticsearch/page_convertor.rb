class Cms::Elasticsearch::PageConvertor
  attr_reader :item

  def initialize(item)
    @item = item
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
    item.files.each do |file|
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
    "page-#{item.id}"
  end

  def item_text
    if Fs.exists?(item.path)
      ApplicationController.helpers.sanitize(Fs.read(item.path).presence || '', tags: [])
    else
      ApplicationController.helpers.sanitize(item.html.presence || '', tags: [])
    end
  end

  class << self
    def with_route(item)
      klass = "#{self.name}::#{item.route.classify.gsub("::", "")}".constantize rescue self
      klass.new(item)
    end
  end
end
