module Cms::Agents::Parts::Tabs
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    include Cms::PublicFilter::Agent

    public
      def index
        @tabs = []

        @cur_part.conditions.each do |path|
          node = Cms::Node.site(@cur_site).public.filename(path).first
          next unless node

          node = node.becomes_with_route

          @tabs << tab = {
            name: node.name,
            url: node.url,
            rss: nil,
            pages: []
          }

          rest = path.sub(/^#{node.filename}/, "")
          spec = recognize_agent "/.#{@cur_site.host}/nodes/#{node.route}#{rest}"
          next unless spec

          node_class = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}/view")
          node_class = "#{node_class}_controller".camelize.constantize

          if node_class.method_defined?(:pages)
            @cur_node = node
            node_cont = invoke_agent node_class, :index
            pages = node_cont.instance_variable_get(:@items) || []
          elsif node.class.method_defined?(:condition_hash)
            pages = Cms::Page.site(@cur_site).public.where(node.condition_hash)
          else
            pages = Cms::Page.site(@cur_site).public.where(cond).node(node)
          end

          if node_class.method_defined?(:rss)
            tab[:rss] = "#{node.url}rss.xml"
          end

          tab[:pages] = pages.order_by(released: -1).limit(@cur_part.limit)
        end

        render
      end
  end
end
