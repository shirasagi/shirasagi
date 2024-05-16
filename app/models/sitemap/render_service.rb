class Sitemap::RenderService
  include ActiveModel::Model

  SITEMAP_XMLNS = "http://www.sitemaps.org/schemas/sitemap/0.9".freeze
  REQUIRED_FIELDS = %i[id _id route name filename site_id depth order redirect_link rss_link].freeze
  EMPTY_ARRAY = [].freeze

  attr_accessor :cur_site, :cur_node, :page

  class UrlItem
    include ActiveModel::Model

    # name may be null
    attr_accessor :url, :filename, :name

    class << self
      def parse(str)
        return if str.blank?

        # split at last delimiter
        name, url = str.reverse.split("#", 2)
        return if name.blank?
        if url.blank?
          url, name = name, url
        end

        if url
          url.strip!
          url.reverse!
        end

        if name
          name.strip!
          name.reverse!
        end

        new(url: url, filename: url_to_filename(url), name: name)
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
      def from_page(page, type: :page, url_item: nil)
        new(
          type: type, id: page.id, name: url_item.try(:name) || page.name, filename: page.filename,
          url: page.url, full_url: page.full_url, order: page.order, depth: page.depth)
      end

      def from_node(node, url_item: nil)
        from_page(node, type: :node, url_item: url_item)
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

    filenames = url_items.map(&:filename)
    filename_url_item_map = url_items.index_by(&:filename)

    page_criteria = Cms::Page.all.site(cur_site).and_public
    page_criteria = page_criteria.where(:depth.lte => page.sitemap_depth)
    page_criteria = page_criteria.in(filename: filenames).only(*REQUIRED_FIELDS)
    pages = page_criteria.to_a.map do |page|
      page.cur_site = cur_site
      page.site = cur_site

      url_item = filename_url_item_map[page.filename]
      FakeContent.from_page(page, url_item: url_item)
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      nil
    end
    pages.compact!

    node_criteria = Cms::Node.all.site(cur_site).and_public
    node_criteria = node_criteria.where(:depth.lte => page.sitemap_depth)
    node_criteria = node_criteria.in(filename: filenames).only(*REQUIRED_FIELDS)
    nodes = node_criteria.to_a.map do |node|
      node.cur_site = cur_site
      node.site = cur_site

      url_item = filename_url_item_map[node.filename]
      FakeContent.from_node(node, url_item: url_item)
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      nil
    end
    nodes.compact!

    filename_index_map = filenames.each.with_index.to_h
    contents = pages + nodes
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
      FakeContent.from_node(node)
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
        FakeContent.from_page(page)
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
end
