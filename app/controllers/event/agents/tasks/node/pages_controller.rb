class Event::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node

      start_date = Date.current.advance(years: -1)
      close_date = Date.current.advance(years:  1, month: 1)
      ym = (start_date..close_date).map{ |date| [ date.year, date.month ] }.uniq
      ym = ym.map { |year, month| [ sprintf("%02d", year), sprintf("%02d", month) ] }

      ym.each do |year, month|
        generate_node @node, file: "#{@node.path}/#{year}#{month}.html", params: { year: year, month: month }
      end
    end

  private
    def render_node(node)
      rest = @cur_path.sub(/^\/#{node.filename}/, "").sub(/\/index\.html$/, "")
      path = "/.#{@cur_site.host}/nodes/#{node.route}#{rest}"

      spec = recognize_agent path
      return unless spec
      spec[:action] = :monthly if params[:month] && params[:year]
      spec[:action] = :daily   if params[:month] && params[:year] && params[:day]

      @cur_node = node
      controller = node.route.sub(/\/.*/, "/agents/#{spec[:cell]}/view")

      agent = new_agent controller
      agent.controller.params.merge! spec

      agent.render spec[:action]
    end
end
