class Guidance::ResultsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Guidance::Result

  navi_view "cms/node/main/navi"

  before_action :set_permissions

  private

  def set_permissions
    @allowed_import = @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [t("mongoid.models.guidance/result"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    @items = @cur_node.guidance_results.
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    set_items
    filename = @cur_node.name + "_" + t("mongoid.models.guidance/result")
    send_enum @items.enum_csv, filename: "#{filename}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new
    return if request.get? || request.head?

    @item.attributes = get_params
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
