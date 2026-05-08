class Cms::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter
  include Cms::NodeImportFilter

  model Cms::Node

  navi_view "cms/main/navi"

  private

  def set_crumbs
    case params[:action]
    when 'download'
      @crumbs << [t("cms.etc"), nil]
      @crumbs << [t("cms.csv_export_node"), action: :download]
    when 'import'
      @crumbs << [t("cms.etc"), nil]
      @crumbs << [t("cms.csv_import_node"), action: :import]
    else
      @crumbs << [t("cms.node"), action: :index]
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  def pre_params
    { route: "cms/node" }
  end

  def redirect_url
    nil
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(depth: 1).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end

  def routes
    @items = {}

    Cms::Node.new.route_options.each do |name, path|
      mod = path.sub(/\/.*/, '')
      @items[mod] = { name: t("modules.#{mod}"), items: [] } if !@items[mod]
      @items[mod][:items] << [ name.sub(/.*\//, ""), path ]
    end

    render layout: "ss/ajax"
  end
end
