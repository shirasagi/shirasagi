class Cms::Agents::Parts::SnsShareController < ApplicationController
  include Cms::PartFilter::View

  def index
    unless instance_variable_defined?(:@cur_page)
      @cur_page = Cms::Page.site(@cur_site).filename(@cur_main_path).and_public.first
    end
    if @cur_page
      @cur_page.cur_site = @cur_site
      @cur_page.site = @cur_site
    end

    unless @cur_page
      unless instance_variable_defined?(:@cur_node)
        @cur_node = Cms::Node.site(@cur_site).in_path(@cur_main_path).and_public.reorder(depth: -1).first
      end
      if @cur_node
        @cur_node.cur_site = @cur_site
        @cur_node.site = @cur_site
      end
    end

    render
  end
end
