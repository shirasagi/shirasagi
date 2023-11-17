class Opendata::Dataset::Metadata::Importer::ReportsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Metadata::Importer::Report

  navi_view "opendata/main/navi"

  private

  def st_categories
    @cur_node.st_categories.presence || @cur_node.default_st_categories
  end

  def st_estat_categories
    @cur_node.st_estat_categories.presence || @cur_node.default_st_estat_categories
  end

  public

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    render_destroy @item.destroy, location: opendata_metadata_path(id: params[:importer_id])
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @items = @item.datasets.order_by(order: 1)

    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @cur_estat_categories = st_estat_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten

    @items = @items.search(params[:s]).page(params[:page]).per(50)
  end

  def dataset
    @item = Opendata::Metadata::Importer::ReportDataset.find(params[:dataset_id])
  end

  def download
    set_item
    csv = @item.to_csv.encode('SJIS', invalid: :replace, undef: :replace)
    send_data csv, filename: "metadata_report_#{Time.zone.now.to_i}.csv"
  end
end
