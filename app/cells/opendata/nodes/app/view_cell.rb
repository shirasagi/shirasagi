# coding: utf-8
module Opendata::Nodes::App
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        @items = Opendata::App.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        @items.empty? ? "" : render
      end

      def show
        @model = Opendata::App
        @item = @model.site(@cur_site).find(params[:id])

        render
      end
  end
end
