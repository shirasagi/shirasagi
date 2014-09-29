# coding: utf-8
module Opendata::Nodes::Sparql
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        return render if params[:query].blank?

        file_format = "#{params[:format]}"
        result = Rdf::Sparql.select("#{params[:query]}", file_format)

        if file_format == "HTML"
          controller.render inline: "#{result[:data]}"
        else
          controller.send_data "#{result[:data]}", type: "#{result[:type]}", filename: "sparql.#{result[:ext]}",
            disposition: :attachment
        end

      end

  end
end
