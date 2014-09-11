# coding: utf-8
module Opendata::Nodes::Idea
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Idea
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        @items = Opendata::Idea.site(@cur_site).
          order_by(updated: -1).
          page(params[:page]).
          per(20)

        @items.empty? ? "" : render
      end

      def show
        @model = Opendata::Idea
        @item = @model.site(@cur_site).find(params[:id])

        render
      end
  end
end
