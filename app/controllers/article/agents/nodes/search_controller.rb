class Article::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]

  helper_method :category_options

  def pages
    Article::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def index
    if params[:reset].present?
      redirect_to @cur_node.url
      return
    end
    @category = params[:category].try { |cate| cate.numeric? ? cate.to_i : nil }
    @keyword = params[:keyword].to_s
    @url = mobile_path? ? ::File.join(@cur_site.mobile_url, @cur_node.filename) : @cur_node.url

    @query = {}
    @query[:category] = @category.blank? ? {} : { :category_ids.in => [ @category ] }
    @query[:keyword] = @keyword.blank? ? {} : @keyword.split(/[\s　]+/).uniq.compact.map(&method(:make_query))

    @items = pages.
      and(@query[:category]).
      and(@query[:keyword]).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)
    render
  end

  def rss
    @items = pages.
      order_by(released: -1).
      limit(@cur_node.limit)

    render_rss @cur_node, @items
  end

  private

  def make_query(query)
    { name: /#{::Regexp.escape(query)}/ }
  end

  def category_options
    @category_options ||= begin
      categories = @cur_node.st_categories.and_public.order_by(order: 1).to_a
      categories.map { |c| [c.name, c.id] }
    end
  end
end
