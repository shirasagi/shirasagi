class Opendata::Agents::Nodes::Dataset::DatasetAreaController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::Dataset::DatasetFilter

  private

  def set_area_node
    @node_url = @cur_node.url
    return if params[:name].blank?

    filename = ::File.join(@cur_node.basename, params[:name])
    @area_node = Cms::Node.site(@cur_site).where(filename: filename).first
    raise "404" unless @area_node

    @area_node = @area_node.becomes_with_route
    @cur_node.name = @area_node.name
    @node_url = "#{@cur_node.url}#{params[:name]}/"
  end

  def pages
    set_area_node

    if @area_node && @area_node.route == "opendata/area"
      Opendata::Dataset.site(@cur_site).search(site: @cur_site, area_id: @area_node.id).and_public
    else
      Opendata::Dataset.site(@cur_site).search(site: @cur_site).and_public
    end
  end

  public

  def index
    @count          = pages.size

    default_options = {}
    default_options = { "s[area_id]" => @area_node.id } if @area_node
    @search_path    = ->(options = {}) { search_datasets_path(default_options.merge(options)) }

    @rss_path       = ->(options = {}) { build_path("#{search_datasets_path}rss.xml", default_options.merge(options)) }
    @items          = pages.order_by(released: -1).limit(10)
    @point_items    = pages.order_by(point: -1).limit(10)
    @download_items = pages.order_by(downloaded: -1).limit(10)

    controller.instance_variable_set :@cur_node, @area_node if @area_node

    @tabs = [
      { name: I18n.t("opendata.sort_options.released"),
        url: @search_path.call("sort" => "released"),
        pages: @items,
        rss: @rss_path.call("sort" => "released") },
      { name: I18n.t("opendata.sort_options.popular"),
        url: @search_path.call("sort" => "popular"),
        pages: @point_items,
        rss: @rss_path.call("sort" => "popular") },
      { name: I18n.t("opendata.sort_options.attention"),
        url: @search_path.call("sort" => "attention"),
        pages: @download_items,
        rss: @rss_path.call("sort" => "attention") }
    ]

    max = 50
    @categories       = aggregate_categories(max)
    @estat_categories = aggregate_estat_categories(max)
    @tags             = aggregate_tags(max)
    @formats          = aggregate_formats(max)
    @licenses         = aggregate_licenses(max)
  end

  def rss
    @items = pages.order_by(released: -1).limit(100)
    render_rss @cur_node, @items
  end
end
