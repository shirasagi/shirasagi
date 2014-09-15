# coding: utf-8
module Category::Parts::Node
  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        @cur_node = @cur_part.parent

        path   = @cur_path.present? ? @cur_path.sub(/^\//, "").sub(/\/[^\/]*$/, "") : nil
        node   = path ? Category::Node::Base.site(@cur_site).where(filename: path).first : nil
        node ||= @cur_node

        if node && node.dirname
          cond = { filename: /^#{node.dirname}\//, depth: node.depth }
        elsif node
          cond = { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        else
          cond = { depth: 1 }
        end

        @items = Category::Node::Base.site(@cur_site).
          where(cond).
          order_by(@cur_part.sort_hash).
          page(params[:page]).
          per(@cur_part.limit)

        render
      end
  end
end
