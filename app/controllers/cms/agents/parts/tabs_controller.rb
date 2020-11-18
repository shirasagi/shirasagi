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

      rest = path.sub(/^#{::Regexp.escape(node.filename)}/, "")
      spec = recognize_agent "/.s#{@cur_site.id}/nodes/#{node.route}#{rest}", method: "GET"
      next unless spec

      node_class = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")
      set_agent(node_class)

      pages = nil

      if @agent.controller.class.method_defined?(:index)
        @cur_node = node
        pages = call_node_index
      end

      if pages.nil?
        if node.class.method_defined?(:condition_hash)
          pages = Cms::Page.public_list(site: @cur_site, node: node, date: @cur_date)
        else
          pages = Cms::Page.site(@cur_site).and_public(@cur_date).where(cond).node(node)
        end
      end

      pages = pages ? pages.order_by(released: -1).limit(@cur_part.limit) : []
      tab[:pages] = pages.map { |item| item.becomes_with_route rescue item }
      tab[:rss]   = "#{node.url}rss.xml" if @agent.controller.class.method_defined?(:rss)
    end

    render
  end

  private

  def set_agent(node_class)
    @agent = new_agent(node_class)
    @agent.controller.params = {}
    @agent.controller.extend(SS::ImplicitRenderFilter)
  end

  def call_node_index
    pages = nil

    begin
      @agent.invoke :index
      pages = @agent.instance_variable_get(:@items)
      pages = nil if pages && !pages.respond_to?(:current_page)
      pages = nil if pages && !pages.klass.include?(Cms::Model::Page)
    rescue => e
      logger.error $ERROR_INFO
      logger.error $ERROR_INFO.backtrace.join("\n")
    end

    pages
  end
end
