module Opendata::Agents::Nodes::Idea
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    public
      def index
        @items = Opendata::Idea.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        render
      end

      def show
        @model = Opendata::Idea
        @item = @model.site(@cur_site).find(params[:id])

        render
      end
  end
end
