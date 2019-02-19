class Opendata::Dataset::ImportDatasetsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::DatasetImporter

  navi_view "opendata/main/navi"
  menu_view nil

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    raise "403" unless Opendata::Dataset.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node)

    @model.new
  end

  def import
    raise "403" unless Opendata::Dataset.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node)

    @item = @model.new

    file = params.dig(:item, :in_file)
    if file.nil?
      @item.errors.add :in_file, :blank
      render file: :index
      return
    end
    if ::File.extname(file.original_filename) != ".zip"
      @item.errors.add :in_file, :invalid_file_type
      render file: :index
      return
    end

    # save csv to use in job
    ss_file = SS::File.new
    ss_file.in_file = file
    ss_file.model = "opendata/import"
    ss_file.save

    # call job
    Opendata::Dataset::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)

    render_create true, location: { action: :import }, notice: I18n.t("ss.notice.started_import")
  end
end
