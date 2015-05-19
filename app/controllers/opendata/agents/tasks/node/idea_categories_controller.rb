class Opendata::Agents::Tasks::Node::IdeaCategoriesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      node_path = @node.path
      node_url  = @node.url

      Opendata::Node::Category.public.where(site_id: @node.site_id).each do |cate|
        path = "#{node_path}/#{cate.basename}/index.html"
        url  = "#{node_url}#{cate.basename}/index.html"
        generate_node @node, url: url, file: path
      end
    end
end
