# coding: utf-8
module Facility::Nodes::Search
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
      def pages
        Facility::Page.site(@cur_site).public
      end

      def index
        #raise "index"
        #if params[:reset].present?
        #  controller.redirect_to "#{@cur_node.url}"
        #end
        #@category = params[:category]
        #@keyword = params[:keyword]

        #@query = {}
        #@query[:category] = @category.blank? ? {} : { :"category_ids".in =>  [@category.to_i] }
        #@query[:keyword] = @keyword.blank? ? {} : @keyword.split(/[\s　]+/).uniq.compact.map { |q| { name: /\Q#{q}\E/ } }

        #@items = pages.
        #  order_by(@cur_node.sort_hash).
        #  and(@query[:category]).
        #  and(@query[:keyword]).
        #  page(params[:page]).
        #  per(@cur_node.limit)
        #render
        @search_path = "./search.html"
        render
      end

      def search
        raise "search"
      end

      def rss
        @items = pages.
          order_by(released: -1).
          limit(@cur_node.limit)

        render_rss @cur_node, @items
      end
  end
end
