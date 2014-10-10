module Opendata::Nodes::SearchDataset
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Opendata::UrlHelper

    public
      def index
        case params[:sort] #TODO:
        when "released"
          sort = { released: -1 }
        when "popular"
          sort = { point: -1 }
        when "attention"
          sort = { downloaded: -1 }
        else
          sort = { released: -1 }
        end

        @model = Opendata::Dataset

        @items = @model.site(@cur_site).public.
          search(params[:s]).
          order_by(sort).
          page(params[:page]).
          per(20)

        render
      end
  end
end
