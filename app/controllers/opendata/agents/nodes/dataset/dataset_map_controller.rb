class Opendata::Agents::Nodes::Dataset::DatasetMapController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  private

  def set_map_points
    @map_points = {}
    @datasets = []
    @items.each do |item|
      resources = []
      item.resources.each_with_index do |resource, idx|
        resource.file.site = @cur_site if resource.file

        if resource.kml_present? || resource.geojson_present?
          key = "#{item.id}_#{idx}"
          name = resource.name

          @map_points[item.id] ||= {}
          @map_points[item.id][key] = {
            format: resource.format,
            url: resource.full_url
          }

          resources << {
            resource: resource,
            key: key,
            name: name,
            type: "layer"
          }
        else
          resource.map_resources.each do |map_resource|
            key = "#{item.id}_#{idx}_#{map_resource["sheet"]}"
            name = resource.tsv_present? ? resource.name : "#{resource.name} [#{map_resource["sheet"]}]"

            @map_points[item.id] ||= {}
            @map_points[item.id][key] = {
              format: resource.format,
              points: map_resource["map_points"]
            }

            resources << {
              resource: resource,
              key: key,
              name: name,
              type: "marker"
            }
          end
        end
      end

      @datasets << [item, resources]
    end
  end

  public

  def index
    view_context.include_map_api(site: @cur_site, api: "openlayers", preview: @preview)
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
          "$or" => [
            { "map_resources" => {"$nin" => [[], nil] } },
            { "format" => "KML" },
            { "format" => "GEOJSON" }
          ]
        }
      }
    }).search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).
      per(10)

    set_map_points

    @cur_node.layout_id = nil
    render layout: 'cms/ajax'
  end
end
