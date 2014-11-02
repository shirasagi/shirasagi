class Urgency::Agents::Nodes::LayoutController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Page

  public
    def index
      page = Cms::Page.where(filename: /index.html$/, depth: @cur_node.depth).first

      raise "404" unless page
      raise "404" unless controller.class.to_s =~ /Preview/

      @cur_node.layout_id = params[:layout]
      @cur_node.name = page.name

      render inline: render_page(page).body
    end

    def empty
      render nothing: true
    end
end
