class Cms::Apis::Node::TempFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model Cms::TempFile

  def index
    @items = @model.site(@cur_site).
      node(@cur_node).
      allow(:read, @cur_user).
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def similar_files
    @in_file = params.dig(:item, :in_files).first

    SS::ReplaceTempFile.user(@cur_user).destroy_all
    @item = SS::ReplaceTempFile.new
    @item.in_file = @in_file
    @item.cur_user = @cur_user
    @item.save

    @filename = params.dig(:similar, :filename).presence
    @filename ||= @in_file.original_filename

    @assoc = params.dig(:similar, :assoc).presence || "assoced"

    @extname = ::File.extname(@in_file.original_filename).to_s.delete(".")
    @humanized_name = "#{@in_file.original_filename} (#{@extname.upcase})"

    set_similar_page_model
    @items = @page_model.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user, site: @cur_site)

    if @assoc == "assoced"
      @items = @items.in(opendata_dataset_state: %w(public closed existance))
    end

    @items = @items.similar_files(@in_file, filename: @filename)
    @items = Kaminari.paginate_array(@items).
      page(params[:page]).
      per(20)

    set_datasets

    render layout: false
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_datasets
    @cur_node = @cur_node.becomes_with_route
    opendata_site_ids = @cur_node.opendata_site_ids rescue []

    @datasets = Opendata::Dataset.in(site_id: opendata_site_ids).
      where(assoc_node_id: @cur_node.id, :assoc_page_id.exists => true).
      map { |dataset| [dataset.assoc_page_id, dataset] }.to_h
  end

  def set_similar_page_model
    if @cur_node.route =~ /^article\//
      @page_model = Article::Page
    else
      @page_model = Cms::Page
    end
  end
end
