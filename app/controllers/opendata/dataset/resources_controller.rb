class Opendata::Dataset::ResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper Opendata::FormHelper

  model Opendata::Resource

  navi_view "opendata/main/navi"

  before_action :set_dataset

  private
    def dataset
      @dataset ||= Opendata::Dataset.site(@cur_site).node(@cur_node).find params[:dataset_id]
    end

    def set_dataset
      raise "403" unless dataset.allowed?(:edit, @cur_user, site: @cur_site)
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
      render_update @item.update
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
