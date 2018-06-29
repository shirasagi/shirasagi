class Urgency::Agents::Nodes::LayoutController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Page

  def index
    page = @cur_node.find_index_page

    raise "404" unless page
    raise "404" unless controller.class.to_s =~ /Preview/

    @cur_node.layout_id = params[:layout]
    @cur_node.name = page.name

    render html: render_page(page).body.html_safe
  end

  def empty
    head :ok
  end
end
