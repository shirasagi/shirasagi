module Opendata::Nodes::Sparql
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        return render if params[:query].blank?

        file_format = params[:format]
        result = Opendata::Sparql.select(params[:query], file_format)

        if file_format == "HTML"
          html_page =  "<!doctype html>"
          html_page += "<html xmlns='http://www.w3.org/1999/xhtml' lang='ja'>\n"
          html_page += "<head>\n"
          html_page += "<meta charset='utf-8'>\n"
          html_page += "<style type='text/css'>"
          html_page += " table, td, th { border: 1px silver solid ; border-collapse: collapse;}"
          html_page += "</style>\n"
          html_page += "<title>SPARQL Results</title>\n"
          html_page += "</head>\n"
          html_page += "<body>\n<h3 style='margin:5px;'>SPARQL Results</h3>\n#{result[:data]}</body>\n"
          html_page += "</html>\n"
          controller.send_data html_page, type: result[:type], disposition: :inline
        else
          controller.send_data result[:data], type: result[:type], filename: "sparql.#{result[:ext]}",
            disposition: :attachment
        end

      end

      def query
        render
      end

  end
end
