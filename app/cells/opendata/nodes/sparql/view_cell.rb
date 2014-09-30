# coding: utf-8
module Opendata::Nodes::Sparql
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        return render if params[:query].blank?

        file_format = params[:format]
        result = Rdf::Sparql.select(params[:query], file_format)

        if file_format == "HTML"
          style = "<meta http-equiv='content-type' content='text/html; charset=utf-8'>\n"
          style += "<style type='text/css'>"
          style += "table, td, th { border: 1px silver solid ; border-collapse: collapse;}"
          style += "</style>"
          data_html = "#{style}\n#{result[:data]}"
          controller.render inline: data_html
        else
          controller.send_data result[:data], type: result[:type], filename: "sparql.#{result[:ext]}",
            disposition: :attachment
        end

      end

  end
end
