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
          html_page =  "<html>\n"
          html_page += "<head>\n"
          html_page += "<meta http-equiv='content-type' content='text/html; charset=utf-8'>\n"
          html_page += "<style type='text/css'>"
          html_page += " table, td, th { border: 1px silver solid ; border-collapse: collapse;}"
          html_page += "</style>\n"
          html_page += "<title>SPARQL Results</title>\n"
          html_page += "</head>\n"
          html_page += "<body>\n<h3>SPARQL Results</h3>\n#{result[:data]}</body>\n"
          html_page += "</html>\n"
          controller.render inline: html_page
        else
          controller.send_data result[:data], type: result[:type], filename: "sparql.#{result[:ext]}",
            disposition: :attachment
        end

      end

  end
end
