class Cms::Agents::Parts::CrumbController < ApplicationController
  include Cms::PartFilter::View

  def index
    @cur_node = @cur_part.parent
    @root_node = @cur_node || @cur_site

    @items = []
    return if @cur_path !~ /^#{@root_node.url}/

    path = @cur_path.sub(/^#{@cur_site.url}/, "")
    parent_crumb_urls = @cur_item.parent_crumb_urls.select(&:present?) rescue nil
    set_items(path, parent_crumb_urls)
  end

  private
    def set_items(path, urls = nil)
      page = Cms::Page.site(@cur_site).filename(path).first
      urls = [path] if urls.blank?

      urls.each do |url|
        item = []
        item << [@cur_part.home_label, @root_node.url]
        find_node(item, url.sub(/^#{@cur_site.url}/, ""))

        item << [@preview_page.name, @preview_page.url] if @preview_page
        if page
          last_item = item.last
          unless last_item[0] == page.name && page.url.end_with?("/index.html")
            item << [page.name, page.url]
          end
        end

        @items << item
      end
    end

    def find_node(item, path)
      Cms::Node.site(@cur_site).in_path(path).order(depth: -1).reverse_each do |node|
        next if @cur_node && @cur_node.depth >= node.depth
        item << [node.name, node.url]
      end
    end
end
