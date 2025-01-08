class Opendata::Agents::Nodes::Dataset::DatasetGraphController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  private

  def set_graph_datasets
    @datasets = []
    @items.each do |item|
      resources = []
      item.resources.each_with_index do |resource, idx|
        next unless resource.preview_graph_enabled?

        key = "#{item.id}_#{idx}"
        name = resource.name
        url = ::File.join(@cur_node.url, "graph", item.id.to_s, resource.id.to_s) + ".json"

        resources << {
          resource: resource,
          key: key,
          name: name,
          url: url
        }
      end

      @datasets << [item, resources]
    end
  end

  public

  def index
  end

  def search
    @model = Opendata::Dataset

    if @cur_node.parent
      @dataset_node = Opendata::Node::Dataset.where(id: @cur_node.parent.id).first
    end

    if @dataset_node
      @items = @model.site(@cur_site).node(@dataset_node)
    else
      @items = @model.site(@cur_site)
    end

    @items = @items.and_public(@cur_date).where({
      "resources" => {
        "$elemMatch" => {
          "$and" => [
            { "preview_graph_state" => "enabled" },
            { "preview_graph_types" => {"$nin" => [[], nil] } },
          ]
        }
      }
    }).search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).
      per(10)

    set_graph_datasets

    @cur_node.layout_id = nil
    render layout: 'cms/ajax'
  end

  def graph
    @model = Opendata::Dataset
    @dataset = @model.site(@cur_site).and_public(@cur_date).where(id: params[:dataset_id]).first
    raise SS::NotFoundError unless @dataset

    @item = @dataset.resources.select { |r| r.id == params[:id].to_i }.first
    raise SS::NotFoundError unless @item

    type = params[:type].presence || @item.preview_graph_types.first
    graph = @item.extract_preview_graph(type)
    raise SS::NotFoundError unless graph

    render json: {
      type: type,
      types: @item.preview_graph_types,
      labels: graph.labels,
      headers: graph.headers,
      datasets: graph.datasets
    }.to_json
  end
end
