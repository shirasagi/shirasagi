module Opendata::Agents::Nodes::Sparql
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    public
      def index
        return render if params[:query].blank?

        file_format = params[:format]
        result = Opendata::Sparql.select(params[:query], file_format)

        if file_format == "HTML"
          html_page = result[:data]
          html_page = html_page.gsub(/<table class="sparql">/, "<table class='sparql' border='1'>")

          @cur_node.layout_id = nil
          headers["Content-Type"] = "text/html; charset='utf-8'"
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
