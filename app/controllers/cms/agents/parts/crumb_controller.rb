class Cms::Agents::Parts::CrumbController < ApplicationController
  include Cms::PartFilter::View

  public
    def index
      @cur_node  = @cur_part.parent
      root_node  = @cur_node || @cur_site

      @items = []
      return if @cur_path !~ /^#{root_node.url}/

      @items << [@cur_part.home_label, root_node.url]

      path = @cur_path.sub(/^#{@cur_site.url}/, "")

      if @cur_item.try(:parent_crumb_urls)[0]
        find_node @cur_item.parent_crumb_urls[0]
      else
        find_node path
      end

      page = Cms::Page.site(@cur_site).filename(path).first
      return unless page

      last_item = @items.last
      return if last_item[0] == page.name && page.url.end_with?("/index.html")

      @items << [page.name, page.url]
    end

  private
    def find_node(path)
      Cms::Node.site(@cur_site).in_path(path).order(depth: 1).each do |node|
        break if @cur_node && @cur_node.id == node.id
        @items << [node.name, node.url]
      end
    end
end
