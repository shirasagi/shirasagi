class Article::Agents::Parts::PageNaviController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def pages
    Article::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def index
    @cur_page = Article::Page.site(@cur_site).where(filename: @cur_main_path.sub(/^\//, "")).first
    @cur_node = @cur_part.parent

    return unless @cur_page
    return unless @cur_node

    @cur_page = @cur_page.becomes_with_route
    @cur_node = @cur_node.becomes_with_route
    ids = pages.order_by(@cur_node.sort_hash).pluck(:id)
    idx = ids.index(@cur_page.id)

    return unless idx

    @center = @cur_node
    prev_idx = (idx - 1) >= 0 ? (idx - 1) : nil
    next_idx = idx + 1

    @prev = Article::Page.find(ids[prev_idx]) rescue nil
    @next = Article::Page.find(ids[next_idx]) rescue nil
  end
end
