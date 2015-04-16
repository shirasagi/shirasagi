class Cms::Agents::Parts::CrumbController < ApplicationController
  include Cms::PartFilter::View

  before_action :set_node
  before_action :set_root
  before_action :set_page

  private
    def set_node
      @cur_node = @cur_part.parent
    end

    def set_root
      @root  = @cur_node || @cur_site
    end

    def set_page
      @cur_page = Cms::Page.site(@cur_site).filename(@cur_path).first if @cur_path =~ /\/[\w\-]+\.[\w\-]+$/
    end

    def append_cur_page
      return if @cur_page.blank?

      if @items.blank? || !@cur_path.end_with?("/index.html") || @items.last[0] != @cur_page.name
        @items << [@cur_page.name, nil]
      end
    end

  public
    def index
      @items = []

      if "#{@cur_path}" =~ /^#{@root.url}/
        url = @cur_path.sub(/^#{@cur_site.url}/, "").sub(/\/([\w\-]+\.[\w\-]+)?$/, "")

        Cms::Node.site(@cur_site).in_path(url).order(depth: -1).each do |node|
          break if @cur_node && @cur_node.id == node.id
          @items.unshift [node.name, node.url]
        end

        append_cur_page
      end

      @items.unshift [@cur_part.home_label, @root.url]

      render
    end
end
