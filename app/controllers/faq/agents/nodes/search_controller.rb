class Faq::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]

  def pages
    Faq::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def index
    if params[:reset].present?
      redirect_to @cur_node.url
      return
    end
    @category = params[:category].try { |cate| cate.numeric? ? cate.to_i : nil }
    @category_ids = params[:category_ids].select(&:numeric?).map(&:to_i) rescue []
    @keyword = params[:keyword].to_s
    @url = mobile_path? ? ::File.join(@cur_site.mobile_url, @cur_node.filename) : @cur_node.url

    @query = {}
    @query[:category] = @category.blank? ? {} : { :category_ids.in => [ @category ] }
    @query[:category_ids] = @category_ids.blank? ? {} : { :category_ids.in => @category_ids }

    @items = pages.
      and(@query[:category]).
      and(@query[:category_ids]).
      keyword_in(@keyword, :name, :html, :question).
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
end
