class Opendata::Dataset::ExportDatasetsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Dataset

  navi_view "opendata/main/navi"
  menu_view nil

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    raise "403" unless Opendata::Dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @item = @model.new
  end

  def export
    raise "403" unless Opendata::Dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    root_url = params.dig(:item, :root_url)

    Opendata::Dataset::ExportJob.bind(site_id: @cur_site.id, user_id: @cur_user, node_id: @cur_node.id).perform_now(root_url: root_url)
    render_create true, location: { action: :start_export }, notice: I18n.t("opendata.notice.start_export")
  end

  def start_export
    #
  end
end
