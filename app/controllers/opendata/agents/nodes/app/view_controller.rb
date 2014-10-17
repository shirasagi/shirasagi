module Opendata::Agents::Nodes::App
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    public
      def index
        @items = Opendata::App.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        render
      end

      def show
        @model = Opendata::App
        @item = @model.site(@cur_site).find(params[:id])

        render
      end
  end
end
