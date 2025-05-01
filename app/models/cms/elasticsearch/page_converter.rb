class Cms::Elasticsearch::PageConverter
  attr_reader :item
  attr_accessor :queue

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
    @html = Fs.exist?(item.path) ? Fs.read(item.path) : item.try(:html)

    doc = {}
    doc[:url] = item.url
    doc[:name] = item.name
    doc[:text] = item_text
    doc[:filename] = item.path
    doc[:state] = item.state
    doc[:category_ids] = item.category_ids
    doc[:categories] = item.categories.pluck(:name)
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:group_names] = item.groups.pluck(:name).map { |n| n.split('/') }.flatten.uniq
    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    doc = parse_doc_image(doc)

    [ index_item_id, doc ]
  end

  def item_text
    return nil unless @html

    marks = SS.config.cms.elasticsearch['site-search-marks']

    html = @html.gsub(/[\s　]+/, ' ')
      .gsub(/<\s*head>.*?<\/head>/i, ' ')
      .gsub(/<\s*script.*?<\/script>/i, ' ')
      .gsub(/<\s*style.*?<\/style>/i, ' ')

    text = [item.name.gsub(/[<>]/, '')]
    html = html.gsub(/<!-- layout_yield -->(.*?)<!-- \/layout_yield -->/) do |m|
      text << m
      ''
    end
    html = html.gsub(/<!--[^>]*?\s#{marks[0]}\s[^>]*?-->(.*?)<!--[^>]*?\s#{marks[1]}\s[^>]*?-->/) do |m|
      text << m
      ''
    end
    text = text.join(' ').gsub(/<.*?>/, ' ').gsub(/  +/, ' ')

    ApplicationController.helpers.sanitize(text.presence || '', tags: [])
  end

  def parse_doc_image(doc)
    if file = item.try(:thumb)
      doc[:image_url] = file.thumb_url
      doc[:image_name] = file.name
      return doc
    end

    m = @html.to_s.scan(/<meta property="og:image" content="(.*?)"/im).flatten
    if image = m[0].presence
      doc[:image_url] = image
      doc[:image_name] = 'og:image'
      return doc
    end

    return doc
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
    # @html
    @file_html = parse_file_html(file)

    doc = {}
    doc[:name] = file_name || file.name
    doc[:path] = file.path
    doc[:url] = file.url
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size
    doc[:state] = item.state
    doc[:page_name] = item.name
    doc[:page_path] = item.path
    doc[:page_url] = item.url
    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)

    [ "file-#{file.id}", doc ]
  end

  def index_item_id
    queue.try(:filename) || item.filename
  end

  def parse_file_html(file)
    return nil unless @html

    pattern = Regexp.escape(file.url)
    if m = @html.match(/<a[^>]*href="#{pattern}".*?>(.*?)<\s*\/a\s*>/im)
      return ::Nokogiri::HTML.parse(m[0])
    end

    pattern = "(#{Regexp.escape(file.url)}|#{Regexp.escape(file.thumb_url)})"
    if m = @html.match(/<img[^>]*src="#{pattern}".*?>/im)
      return ::Nokogiri::HTML.parse(m[0])
    end

    return nil
  end

  def file_name
    return nil unless @file_html

    el = @file_html.xpath("//a")
    value = el.attr('alt').try(:value) || el.attr('title').try(:value)
    return value if value.present?

    el = @file_html.xpath("//img")
    value = el.attr('alt').try(:value) || el.attr('title').try(:value)
    return value if value.present?

    return @file_html.text.strip.sub(/ \(\w+ \d+\w+\)/i, '').presence
  end

  class << self
    def with_route(item, opts = {})
      klass = "#{self.name}::#{item.route.classify.gsub("::", "")}".constantize rescue self
      converter = klass.new(item)
      converter.queue = opts[:queue]
      converter
    end
  end
end
