class Cms::Agents::Parts::TabsController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Agent

  def index
    @tabs = []

    @cur_part.conditions.each do |path|
      node = Cms::Node.site(@cur_site).and_public.filename(path).first
      next unless node

      node = node.becomes_with_route

      @tabs << tab = { name: node.name, url: node.url, rss: nil, pages: [] }

      rest = path.sub(/^#{node.filename}/, "")
      spec = recognize_agent "/.s#{@cur_site.id}/nodes/#{node.route}#{rest}", method: "GET"
      next unless spec

      node_class = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")
      node_class = "#{node_class}_controller".camelize.constantize

      pages = nil

      if node_class.method_defined?(:index)
        @cur_node = node
        pages = call_node_index(node_class)
      end

      if pages.nil?
        if node.class.method_defined?(:condition_hash)
          pages = Cms::Page.site(@cur_site).and_public(@cur_date).where(node.condition_hash)
        else
          pages = Cms::Page.site(@cur_site).and_public(@cur_date).where(cond).node(node)
        end
      end

      pages = pages ? pages.order_by(released: -1).limit(@cur_part.limit) : []
      tab[:pages] = pages.map { |item| item.becomes_with_route rescue item }
      tab[:rss]   = "#{node.url}rss.xml" if node_class.method_defined?(:rss)
    end

    render
  end

  private

  def call_node_index(node_class)
    cont = new_agent(node_class)
    cont.controller.params = {}

    pages = nil

    begin
      cont.invoke :index
      pages = cont.instance_variable_get(:@items)
      pages = nil if pages && !pages.respond_to?(:current_page)
      pages = nil if pages && !pages.klass.include?(Cms::Model::Page)
    rescue => e
      logger.error $ERROR_INFO
      logger.error $ERROR_INFO.backtrace.join("\n")
    end

    pages
  end
end
