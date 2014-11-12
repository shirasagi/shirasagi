class Cms::Agents::Parts::TabsController < ApplicationController
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

        node_class = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")
        node_class = "#{node_class}_controller".camelize.constantize

        pages = nil

        if node_class.method_defined?(:index)
          @cur_node = node
          cont  = invoke_agent node_class, :index
          pages = cont.instance_variable_get(:@items)
          pages = nil if pages && !pages.respond_to?(:current_page)
          pages = nil if pages && !pages.klass.include?(Cms::Page::Model)
        end

        if pages.nil?
          if node.class.method_defined?(:condition_hash)
            pages = Cms::Page.site(@cur_site).public(@cur_date).where(node.condition_hash)
          else
            pages = Cms::Page.site(@cur_site).public(@cur_date).where(cond).node(node)
          end
        end

        tab[:pages] = pages ? pages.order_by(released: -1).limit(@cur_part.limit) : []
        tab[:rss]   = "#{node.url}rss.xml" if node_class.method_defined?(:rss)
      end

      render
    end
end
