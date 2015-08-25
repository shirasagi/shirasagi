class Faq::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]

  public
    def pages
      Faq::Page.site(@cur_site).public(@cur_date)
    end

    def index
      if params[:reset].present?
        redirect_to "#{@cur_node.url}"
        return
      end
      @category = params[:category]
      @keyword = params[:keyword]
      @url = mobile_path? ? "#{SS.config.mobile.location}#{@cur_node.url}" : @cur_node.url

      @query = {}
      @query[:category] = @category.blank? ? {} : { :category_ids.in => [@category.to_i] }
      @query[:keyword] = @keyword.blank? ? {} : @keyword.split(/[\s　]+/).uniq.compact.map(&method(:make_query))

      @items = pages.
        and(@query[:category]).
        and(@query[:keyword]).
        and(@cur_node.condition_hash).
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
    def make_query(q)
      { name: /#{Regexp.escape(q)}/ }
    end
end
