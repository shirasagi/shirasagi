class Cms::Agents::Parts::TabsController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Agent
  helper Cms::TabsHelper

  def index
    @tabs = []
    save_site = @cur_site
    save_node = @cur_node

    @cur_part.interpret_conditions(site: @cur_site, default_location: :never, request_dir: false) do |site, content_or_path|
      if content_or_path.is_a?(Cms::Content) || content_or_path == :root_contents || content_or_path.end_with?("*")
        # - default content is not supported
        # - root content is not supported
        # - wildcard is not supported
        next
      end

      node = Cms::Node.site(site).and_public(@cur_date).filename(content_or_path).first
      next unless node

      @tabs << tab = { name: node.name, url: node.url, rss: nil, pages: [] }

      rest = content_or_path.sub(/^#{::Regexp.escape(node.filename)}/, "")
      spec = recognize_agent "/.s#{site.id}/nodes/#{node.route}#{rest}", method: "GET"
      next unless spec

      node_class = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}")
      set_agent(node_class)

      #pages = nil
      #
      #if @agent.controller.class.method_defined?(:index)
      #  begin
      #    @cur_site = site
      #    @cur_node = node
      #    pages = call_node_index
      #  ensure
      #    @cur_site = save_site
      #    @cur_node = save_node
      #  end
      #end
      #
      #if pages.nil?
      #  if node.class.method_defined?(:condition_hash)
      #    pages = Cms::Page.public_list(site: site, node: node, date: @cur_date)
      #  else
      #    pages = Cms::Page.site(site).and_public(@cur_date).node(node)
      #  end
      #end

      if node.class.method_defined?(:condition_hash)
        pages = Cms::Page.public_list(site: site, node: node, date: @cur_date)
      else
        pages = Cms::Page.site(site).and_public(@cur_date).node(node)
      end
      pages = pages ? pages.order_by(released: -1).limit(@cur_part.limit) : []
      tab[:pages] = pages.to_a
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

  #def call_node_index
  #  pages = nil
  #
  #  begin
  #    @agent.invoke :index
  #    pages = @agent.instance_variable_get(:@items)
  #    pages = nil if pages && !pages.respond_to?(:current_page)
  #    pages = nil if pages && !pages.klass.include?(Cms::Model::Page)
  #  rescue => e
  #    logger.error $ERROR_INFO
  #    logger.error $ERROR_INFO.backtrace.join("\n")
  #  end
  #
  #  pages
  #end
end
