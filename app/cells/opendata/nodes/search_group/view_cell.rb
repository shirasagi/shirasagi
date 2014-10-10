module Opendata::Nodes::SearchGroup
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Opendata::UrlHelper

    public
      def index
        @items = Opendata::DatasetGroup.site(@cur_site).public.
          search(params[:s]).
          order_by(name: 1).
          page(params[:page]).
          per(20)

        render
      end
  end
end
