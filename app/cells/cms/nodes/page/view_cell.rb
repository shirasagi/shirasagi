module Cms::Nodes::Page
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
      def pages
        Cms::Page.site(@cur_site).public.
          where(@cur_node.condition_hash)
      end

      def index
        @items = pages.
          order_by(@cur_node.sort_hash).
          page(params[:page]).
          per(@cur_node.limit)

        render_with_pagination @items
      end

      def rss
        @items = pages.
          order_by(publushed: -1).
          per(@cur_node.limit)

        render_rss @cur_node, @items
      end
  end
end
