# coding: utf-8
module Cms::Parts::Crumb
  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell

    public
      def index
        @cur_node = @cur_part.parent

        @root  = @cur_node || @cur_site
        @items = []

        if "#{@cur_path}" =~ /^#{@root.url}/
          url = @cur_path.sub(/^#{@cur_site.url}/, "").sub(/\/([\w\-]+\.[\w\-]+)?$/, "")

          Cms::Node.site(@cur_site).in_path(url).order(depth: -1).each do |node|
            break if @cur_node && @cur_node.id == node.id
            @items.unshift [node.name, node.url]
          end

          if @cur_path =~ /\/[\w\-]+\.[\w\-]+$/
            page = Cms::Page.site(@cur_site).filename(@cur_path).first
            @items << [page.name, nil] if page
          end
        end

        @items.unshift [@cur_part.home_label, @root.url]

        @items.empty? ? "" : render
      end
  end
end
