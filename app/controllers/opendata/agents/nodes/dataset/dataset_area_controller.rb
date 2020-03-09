class Opendata::Agents::Nodes::Dataset::DatasetAreaController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include Opendata::Dataset::DatasetFilter

  private

  def pages
    @cur_node.cur_subcategory = params[:name]
    @item = @cur_node.related_area
    raise "404" unless @item

    @cur_node.name = @item.name

    if @item.route == "opendata/area"
      Opendata::Dataset.site(@cur_site).search(site: @cur_site, area_id: @item.id).and_public
    else
      area_ids = Opendata::Node::Area.site(@cur_site).where(filename: /^#{::Regexp.escape(@item.filename)}\//).pluck(:id)
      Opendata::Dataset.site(@cur_site).in(area_ids: area_ids).and_public
    end
  end

  def node_url
    if name = params[:name]
      "#{@cur_node.url}#{name}/"
    else
      @cur_node.url
    end
  end

  public

  def index
    @count          = pages.size
    @node_url       = node_url
    @dataset_path   = dataset_path
    default_options = { "s[area_id]" => @item.id }
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
