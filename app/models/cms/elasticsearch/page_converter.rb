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
    @site = item.site
    @html = Fs.exist?(item.path) ? Fs.read(item.path) : item.try(:html)
    @content_html = nil

    doc = {}
    doc[:site_id] = @site.id
    doc[:url] = item.url
    doc[:full_url] = item.full_url
    doc[:name] = item.name
    doc[:text] = item_text
    doc[:filename] = item.path
    doc[:state] = item.state
    doc[:category_ids] = item.category_ids
    doc[:categories] = item.categories.pluck(:name)
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:groups] = item.groups.pluck(:name).map { |n| n.split('/') }.flatten.uniq
    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = item.updated.try(:iso8601)
    doc[:created] = item.created.try(:iso8601)

    if image = item_image
      doc[:image_url] = image[:url]
      doc[:image_full_url] = image[:full_url]
      doc[:image_name] = image[:name]
    end

    [ index_item_id, doc ]
  end

  def item_text
    return nil unless @html

    marks = SS.config.cms.elasticsearch['site-search-marks']

    html = @html.gsub(/[\s　]+/, ' ')
      .gsub(/<\s*head>.*?<\/head>/i, ' ')
      .gsub(/<\s*script.*?<\/script>/i, ' ')
      .gsub(/<\s*style.*?<\/style>/i, ' ')

    text = []
    html = html.gsub(/<!-- layout_yield -->(.*?)<!-- \/layout_yield -->/) do |m|
      @content_html = ::Nokogiri::HTML.parse(m)
      text << m
      ''
    end
    html = html.gsub(/<!--[^>]*?\s#{marks[0]}\s[^>]*?-->(.*?)<!--[^>]*?\s#{marks[1]}\s[^>]*?-->/) do |m|
      text << m
      ''
    end
    if text.empty?
      @content_html = ::Nokogiri::HTML.parse(html)
      text << html
    end
    text = text.join(' ').gsub(/<.*?>/, ' ').gsub(/  +/, ' ')

    ApplicationController.helpers.sanitize(text.presence || '', tags: [])
  end

  def item_image
    if file = item.try(:thumb)
      return { url: file.thumb_url, full_url: "#{@site.full_root_url}#{file.thumb_url[1..-1]}", name: file.name }
    end

    if @content_html
      @content_html.xpath("//img").each do |el|
        src = el.attr('src')
        next unless src.present?
        alt = el.attr('alt').presence || el.attr('title').presence || 'Image'

        [src.sub(/(\.\w+)$/, '_thumb\\1'), src].each do |path|
          next unless ::File.exist?("#{@site.root_path}#{path}")
          return { url: path, full_url: "#{@site.full_root_url}#{path[1..-1]}", name: alt }
        end
      end
    end

    # m = @html.to_s.scan(/<meta property="og:image" content="(.*?)"/im).flatten
    # if file = m[0].presence
    #   return { url: file, name: 'og:image' }
    # end

    return nil
  end

  def index_item_id
    queue.try(:filename) || item.filename
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
    @file_html = parse_file_html(file)

    doc = {}
    doc[:site_id] = @site.id
    doc[:name] = file_name || file.name
    doc[:path] = file.public_path
    doc[:url] = file.url
    doc[:full_url] = file.full_url
    doc[:data] = Base64.strict_encode64(::File.binread(file.path))
    doc[:file] = {}
    doc[:file][:extname] = file.extname.upcase
    doc[:file][:size] = file.size
    doc[:state] = item.state
    doc[:category_ids] = item.category_ids
    doc[:categories] = item.categories.pluck(:name)
    doc[:group_ids] = item.groups.pluck(:id)
    doc[:groups] = item.groups.pluck(:name).map { |n| n.split('/') }.flatten.uniq
    doc[:released] = item.released.try(:iso8601)
    doc[:updated] = file.updated.try(:iso8601)
    doc[:created] = file.created.try(:iso8601)
    doc[:page_name] = item.name
    doc[:page_path] = item.path
    doc[:page_url] = item.url
    doc[:page_full_url] = item.full_url

    [ "file-#{file.id}", doc ]
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
