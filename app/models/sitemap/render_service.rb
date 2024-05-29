class Sitemap::RenderService
  include ActiveModel::Model

  SITEMAP_XMLNS = "http://www.sitemaps.org/schemas/sitemap/0.9".freeze
  REQUIRED_FIELDS = %i[id _id route name filename site_id depth order redirect_link rss_link].freeze
  EMPTY_ARRAY = [].freeze

  attr_accessor :cur_site, :cur_node, :page

  class UrlItem
    include ActiveModel::Model

    # name may be null
    attr_accessor :authority, :url, :filename, :name

    class << self
      def parse(str)
        return if str.blank?

        # split at last delimiter
        name, url = str.reverse.split("#", 2)
        return if name.blank?
        if url.blank?
          url, name = name, url
        end
        return if url.blank?

        url.strip!
        url.reverse!
        url = ::Addressable::URI.parse(url)

        if name
          name.strip!
          name.reverse!
        end

        new(authority: url.authority, url: url.request_uri, filename: url_to_filename(url.request_uri), name: name)
      end

      private

      def url_to_filename(url)
        url.sub(/^\//, "").sub(/\/$/, "")
      end
    end
  end

  class FakeContent
    include ActiveModel::Model

    attr_accessor :type, :id, :name, :filename, :url, :full_url, :depth, :order

    class << self
      def from_page(page, cur_site:, type: :page, url_item: nil)
        new(
          type: type, id: page.id, name: url_item.try(:name) || page.name, filename: page.filename,
          url: page.url, full_url: page.full_url, order: page.order, depth: page.depth)
      end

      def from_node(node, cur_site:, url_item: nil)
        from_page(node, cur_site: cur_site, type: :node, url_item: url_item)
      end

      def from_node_sub_url(node, cur_site:, url_item:)
        full_url = ::Addressable::URI.join(cur_site.full_url, url_item.url).to_s

        new(
          type: :node_sub_url, id: node.id, name: url_item.try(:name) || node.name,
          filename: url_item.try(:filename) || node.filename,
          url: url_item.try(:url) || node.url, full_url: full_url, order: node.order, depth: node.depth)
      end
    end
  end

  def contents
    load_contents
  end

  def render_xml
    site_url = cur_site.full_url

    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.urlset(xmlns: SITEMAP_XMLNS) do |url_set|
        url_set.url do |url|
          url.loc site_url
          url.priority 1.0
        end

        load_contents.each do |content|
          page_url = content.full_url

          url_set.url do |url|
            priority = "0.8"
            priority = "0.5" if page.depth > 3

            url.loc page_url
            url.priority priority
          end
        end
      end
    end

    builder.to_xml
  end

  def load_contents
    if page.sitemap_urls.present?
      load_contents_with_urls
    else
      load_whole_contents
    end
  end

  def load_contents_with_urls
    return EMPTY_ARRAY if page.sitemap_urls.blank?

    url_items = page.sitemap_urls.map { |url| UrlItem.parse(url) }
    url_items.compact!
    return EMPTY_ARRAY if url_items.blank?

    url_items.select! do |url_item|
      next true if url_item.authority.blank?
      cur_site.domains.include?(url_item.authority)
    end
    return EMPTY_ARRAY if url_items.blank?

    contents = url_items.map do |url_item|
      create_fake_content(url_item)
    end
    contents.compact!

    filenames = url_items.map(&:filename)
    filename_index_map = filenames.each.with_index.to_h
    contents.sort_by! { |content| filename_index_map[content.filename] || 1_000_000 }
    contents
  end

  def load_whole_contents
    nodes = Cms::Node.site(cur_site).and_public.
      where(:depth.lte => page.sitemap_depth).
      reorder(filename: 1).
      only(*REQUIRED_FIELDS).
      to_a
    entries = nodes.map do |node|
      node.cur_site = cur_site
      node.site = cur_site
      FakeContent.from_node(node, cur_site: cur_site)
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      nil
    end

    if page.sitemap_page_state != "hide"
      pages = Cms::Page.site(cur_site).and_public.
        where(:depth.lte => page.sitemap_depth).
        not(filename: /\/index\.html$/).
        reorder(filename: 1).
        only(*REQUIRED_FIELDS).
        to_a
      entries += pages.map do |page|
        page.cur_site = cur_site
        page.site = cur_site
        FakeContent.from_page(page, cur_site: cur_site)
      rescue => e
        Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
        nil
      end
    end
    entries.compact!

    # deny
    if page.sitemap_deny_urls.present?
      regex = page.sitemap_deny_urls.map { |m| /^\/?#{::Regexp.escape(m)}/ }
      regex = ::Regexp.union(regex)
      entries.reject! { |e| regex.match(e.url) }
    end

    # sort by order
    tree = {}

    entries.each do |e|
      dirname = ::File.dirname(e.filename)
      dirname = "" if dirname[0] == "."

      tree[dirname] ||= []
      tree[dirname] << e
    end
    tree.each_value { |v| v.sort_by!(&:order) }

    flatten_tree(tree, "", [])
  end

  private

  def flatten_tree(tree, dirname, entries)
    return entries unless tree[dirname]

    tree[dirname].each do |e|
      entries << e
      flatten_tree(tree, e.filename, entries)
    end

    entries
  end

  def create_fake_content(url_item)
    filename = url_item.filename
    extname = ::File.extname(filename)
    if extname.present?
      filename = filename.sub(extname, ".html") if extname != ".html"
      page = filename_to_page_map[filename]
    end
    return FakeContent.from_page(page, cur_site: cur_site, url_item: url_item) if page

    filename = ::File.dirname(filename) if extname.present?
    node = filename_to_node_map[filename]
    return FakeContent.from_node(node, cur_site: cur_site, url_item: url_item) if node

    loop do
      prev_filename = filename
      filename = ::File.dirname(filename)
      break if filename.blank? || filename == "/" || prev_filename == filename

      node = filename_to_node_map[filename]
      next unless node

      rest = url_item.filename[filename.length..-1]
      path = "/.s#{cur_site.id}/nodes/#{node.route}#{rest}"
      spec = Rails.application.routes.recognize_path(path, method: "GET") rescue {}
      return FakeContent.from_node_sub_url(node, cur_site: cur_site, url_item: url_item) if node if spec[:cell]
    end

    nil
  end

  def all_pages
    @all_pages ||= begin
      criteria = Cms::Page.site(cur_site)
      criteria = criteria.and_public
      criteria = criteria.where(:depth.lte => page.sitemap_depth)
      criteria.only(*REQUIRED_FIELDS).to_a
    end
  end

  def all_nodes
    @all_nodes ||= begin
      criteria = Cms::Node.site(cur_site)
      criteria = criteria.and_public
      criteria = criteria.where(:depth.lte => page.sitemap_depth)
      criteria.only(*REQUIRED_FIELDS).to_a
    end
  end

  def filename_to_page_map
    @filename_to_page_map ||= all_pages.index_by(&:filename)
  end

  def filename_to_node_map
    @filename_to_node_map ||= all_nodes.index_by(&:filename)
  end
end
