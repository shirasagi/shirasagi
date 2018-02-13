class Opendata::Agents::Tasks::Node::SearchAppController < ApplicationController
  include Cms::PublicFilter::Node

  def generate_search_file(node)
    return unless node.serve_static_file?

    @model = node.class
    @cur_site = node.site
    @cur_node = Opendata::Node::SearchApp.site(@cur_site).and_public.first
    @cur_categories = st_categories.map do |cate|
      next if cate.blank?
      next if cate.children.blank?
      cate.children.and_public.sort(order: 1).to_a
    end
    @cur_categories.flatten!
    file = node.app_search_html_path

    agent = SS::Agent.new self.class
    self.params   = agent.controller.params
    self.request  = agent.controller.request
    self.response = agent.controller.response

    response.body = render partial: 'opendata/agents/nodes/app/search_app/search'
    response.content_type ||= "text/html"

    return if Fs.exists?(file) && response.body == Fs.read(file)

    Fs.write(file, response.body)
  end

  private

  def st_categories
    node = Opendata::Node::App.site(@cur_site).and_public.first
    node.st_categories.presence || node.default_st_categories
  end
end
