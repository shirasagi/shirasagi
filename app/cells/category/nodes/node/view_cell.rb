# coding: utf-8
module Category::Nodes::Node
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        @items = Category::Node::Base.site(@cur_site).public.
          where(@cur_node.condition_hash).
          order_by(@cur_node.sort_hash).
          page(params[:page]).
          per(@cur_node.limit)

        @items.empty? ? "" : render
      end
  end
end
