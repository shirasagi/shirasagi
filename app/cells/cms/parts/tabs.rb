# coding: utf-8
module Cms::Parts::Tabs
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Tabs
  end

  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    include Cms::ReleaseFilter

    public
      def index
        @tabs = []

        @cur_part.conditions.each do |path|
          node = Cms::Node.site(@cur_site).public.find_by filename: path
          next unless node

          node = node.becomes_with_route

          @tabs << tab = {
            name: node.name,
            url: node.url,
            rss: nil,
            pages: []
          }

          rest = path.sub(/^#{node.filename}/, "")
          cell = recognize_path "/.#{@cur_site.host}/nodes/#{node.route}#{rest}"
          next unless cell

          ctrl = node.route.sub(/\/.*/, "/#{cell[:controller]}/view")
          cell = "#{ctrl}_cell".camelize.constantize

          if cell.method_defined?(:pages)
            controller.instance_variable_set(:@cur_node, node)
            pages = controller.render_cell(ctrl, "pages")
          elsif node.class.method_defined?(:condition_hash)
            pages = Cms::Page.site(@cur_site).public.where(node.condition_hash)
          else
            cond = { filename: /^#{node.filename}\//, depth: node.depth + 1 }
            pages = Cms::Page.site(@cur_site).public.where(cond)
          end

          if cell.method_defined?(:rss)
            tab[:rss] = "#{node.url}rss.xml"
          end

          tab[:pages] = pages.order_by(released: -1).limit(@cur_part.limit)
        end

        render
      end
  end
end
