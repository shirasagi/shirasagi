class Opendata::Harvest::ExportersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Harvest::Exporter

  navi_view "opendata/main/navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :export]
  before_action :append_crumbs

  def append_crumbs
    @crumbs << [@item.name, opendata_harvest_exporter_path(@item)] if @item
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def index
    @items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user, site: @cur_site)
  end

  def export
    set_item
    return if request.get? || request.head?

    Opendata::Harvest::ExportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(exporters: [@item.id])
    flash.now[:notice] = I18n.t("ss.notice.started_export")
  end
end
