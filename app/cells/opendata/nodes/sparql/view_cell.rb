# coding: utf-8
module Opendata::Nodes::Sparql
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        return render if params[:query].blank?

        data = { key: "test" }
        controller.render json: data.to_json
      end
  end
end
