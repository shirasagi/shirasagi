class Opendata::Dataset::Harvest::ImportersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Harvest::Importer

  navi_view "opendata/main/navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :import, :destroy_datasets]
  before_action :append_crumbs

  def append_crumbs
    @crumbs << [@item.name, opendata_harvest_importer_path(@item)] if @item
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def index
    @items = Opendata::Harvest::Importer.site(@cur_site).node(@cur_node)
      .allow(:read, @cur_user, site: @cur_site)
  end

  def import
    return if request.get?

    Opendata::Harvest::ImportDatasetsJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(@item.id)
    flash.now[:notice] = I18n.t("opendata.errors.messages.import_started")
  end

  def destroy_datasets
    return if request.get?

    Opendata::Harvest::DestroyDatasetsJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(@item.id)
    flash.now[:notice] = I18n.t("opendata.errors.messages.destroy_started")
  end
end
