# coding: utf-8
module Opendata::Nodes::Sparql
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        return render if params[:query].blank?

        file_format = "#{params[:format]}"
        sparql = Rdf::Sparql.new
        data = sparql.select("#{params[:query]}", file_format)

        if file_format == "HTML"
          controller.render inline: data
        elsif file_format == "JSON" then
          controller.render json: data.to_s
        elsif file_format == "CSV" then
          controller.render text: data
        elsif file_format == "TSV" then
          controller.render text: data
        elsif file_format == "XML" then
          controller.render xml: data.to_s
        end

      end

      def query
        render
      end
  end
end
