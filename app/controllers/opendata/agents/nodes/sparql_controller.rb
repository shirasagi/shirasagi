class Opendata::Agents::Nodes::SparqlController < ApplicationController
  include Cms::NodeFilter::View

  before_action :accept_cors_request

  def index
    if params[:query].blank?

      graph_name = params[:graph_name].blank? ? "?g" : "<#{params[:graph_name]}>"

      @default_query = "select distinct * where { graph #{graph_name} { ?s ?p ?o . } } limit 100"

      return render
    end

    file_format = params[:format]
    result = Opendata::Sparql.select(params[:query], file_format)

    if result == true
      send_data "Disabled", type: "text/html", disposition: :inline
    elsif file_format == "HTML"
      html_result = result[:data]
      if html_result.include?(%(<td>))
        html_page =  %(<html>\n<head><meta charset="utf-8"></head>\n<body>\n)
        html_page += html_result.gsub(/<table class="sparql">/, %(<table class="sparql" border="1">) )
        html_page += %(</body>\n</html>\n)
      else
        html_page = %(<h1>No Data</h1>)
      end

      @cur_node.layout_id = nil
      send_data html_page, type: result[:type], disposition: :inline
    elsif file_format == "HTML_TABLE"
      html_result = result[:data]
      if html_result.include?(%(<td>))
        html_page = html_result.gsub(/<table class="sparql">/, %(<table class="sparql" border="1">) )
      else
        html_page = %(<h1>No Data</h1>)
      end

      @cur_node.layout_id = nil
      send_data html_page, type: result[:type], disposition: :inline
    else
      send_data result[:data], type: result[:type], filename: "sparql.#{result[:ext]}",
        disposition: :attachment
    end
  end
end
