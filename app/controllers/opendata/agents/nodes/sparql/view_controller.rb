module Opendata::Agents::Nodes::Sparql
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    before_action :accept_cors_request

    public
      def index
        return render if params[:query].blank?

        file_format = params[:format]
        result = Opendata::Sparql.select(params[:query], file_format)

        if file_format == "HTML"

          html_result = result[:data]
          if html_result.include?("<td>")
            html_page =  "<html>\n<head><meta charset='utf-8'></head>\n<body>\n"
            html_page += html_result.gsub(/<table class="sparql">/, "<table class='sparql' border='1'>")
            html_page += "</body>\n</html>\n"
          else
            html_page = "<h1>No Data</h1>"
          end

          @cur_node.layout_id = nil
          #headers["Content-Type"] = "text/html; charset='utf-8'"
          send_data html_page, type: result[:type], disposition: :inline
        else
          send_data result[:data], type: result[:type], filename: "sparql.#{result[:ext]}",
            disposition: :attachment
        end

      end

      def query
        render
      end

  end
end
