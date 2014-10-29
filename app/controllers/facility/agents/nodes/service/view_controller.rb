module Facility::Agents::Nodes::Service
  class ViewController < ApplicationController
    include Cms::NodeFilter::View
    helper Cms::ListHelper

    public
      def index
        @items = Facility::Node::Page.site(@cur_site).public.
          in(service_ids: @cur_node.id).
          order_by(@cur_node.sort_hash).
          page(params[:page]).
          per(@cur_node.limit)

        @items.empty? ? "" : render
      end
  end
end
