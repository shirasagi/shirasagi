class Opendata::Dataset::ResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Resource

  navi_view "opendata/main/navi"

  before_action :set_dataset

  private

  def dataset
    @dataset ||= Opendata::Dataset.site(@cur_site).node(@cur_node).find params[:dataset_id]
  end

  def set_dataset
    raise "403" unless dataset.allowed?(:read, @cur_user, site: @cur_site)
    @crumbs << [@dataset.name, opendata_dataset_path(id: @dataset)]
  end

  def set_item
    @item = dataset.resources.find params[:id]
  end

  def pre_params
    default_license = Opendata::License.site(@cur_site).and_public.and_default.order_by(order: 1, id: 1).first
    if default_license.present?
      { license_id: default_license.id }
    else
      {}
    end
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @items = dataset.resources.in(id: ids)
    raise "400" unless @items.present?
  end

  def csv2_rdf_setting_exist?
    Opendata::Csv2rdfSetting.site(@cur_site).resource(@item).present?
  end

  public

  def index
    raise "403" unless @dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @items = @dataset.resources.
      search(params[:s]).
      order_by(name: 1).
      page(params[:page]).per(50)
  end

  def create
    raise "403" unless @dataset.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @item = @dataset.resources.new get_params
    @item.status = params[:item][:state]
    @item.workflow = { workflow_reset: true } if @dataset.member.present?
    render_create @item.save
  end

  def update
    raise "403" unless @dataset.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @item.attributes = get_params
    @item.status = params[:item][:state]
    @item.workflow = { workflow_reset: true } if @dataset.member.present?
    result = @item.save

    if result && csv2_rdf_setting_exist?
      location = url_for(controller: :csv2rdf_settings, action: :guidance, resource_id: @item)
      redirect_to location, notice: t("ss.notice.saved")
      return
    end

    render_update result
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    render_destroy @item.validate_and_destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.validate_and_destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def download
    raise "403" unless @dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @item = @dataset.resources.find params[:resource_id]
    send_file @item.file.path, type: @item.content_type, filename: @item.filename,
      disposition: :attachment, x_sendfile: true
  end

  def download_tsv
    @item = @dataset.resources.find params[:resource_id]
    raise "404" if @item.tsv.blank?
    raise "403" unless @dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    send_file @item.tsv.path, type: @item.content_type, filename: @item.tsv.filename,
      disposition: :attachment, x_sendfile: true
  end

  def content
    raise "403" unless @dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @item = @dataset.resources.find params[:resource_id]
    @data = @item.parse_tsv
  end

  def check_for_update
    set_item
    raise "403" unless @dataset.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    render layout: "ss/ajax"
  end

  def sync
    set_item
    raise "403" unless @dataset.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    return if request.get?

    page = @item.assoc_page
    file = @item.assoc_file
    @item.update_resource_with_file!(page, file, @item.license_id)
    render_update true, render: { file: :sync }
  rescue => e
    @item.errors.add :base, e.message
    render_update false, render: { file: :sync }
  end
end
