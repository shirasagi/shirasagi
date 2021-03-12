class Chorg::EntityLogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :filter_permission
  before_action :set_revision
  before_action :set_crumbs
  before_action :set_task

  model Chorg::Task

  navi_view 'cms/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), controller: :revisions, action: :index]
    @crumbs << [@cur_revision.name, chorg_revision_path(id: @cur_revision.id)]
  end

  def filter_permission
    raise "403" unless Chorg::Revision.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_revision
    @cur_revision = Chorg::Revision.find(params[:rid])
    raise "403" unless @cur_revision.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  def set_task
    criteria = Chorg::Task.site(@cur_site)
    criteria = criteria.and_revision(@cur_revision)
    criteria = criteria.where(name: "chorg:#{params[:type]}_task")
    @cur_task = criteria.order_by(created: -1).first_or_create
  end

  public

  def index
    @items = @cur_task.entity_logs
    @items ||= []
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
  end

  def show_models
    @entity_site = @cur_task.entity_log_sites[params[:entity_site]]
    raise "404" unless @entity_site

    @items = @entity_site["models"]
  end

  def show_entities
    @entity_site = @cur_task.entity_log_sites[params[:entity_site]]
    raise "404" unless @entity_site

    @entity_model = @entity_site["models"][params[:entity_model]]
    raise "404" unless @entity_model

    @items = @entity_model["items"]
  end

  def show_entity
    @entity_site = @cur_task.entity_log_sites[params[:entity_site]]
    raise "404" unless @entity_site

    @entity_model = @entity_site["models"][params[:entity_model]]
    raise "404" unless @entity_model

    @item = @entity_model["items"][params[:entity_index]]
    raise "404" unless @item
  end

  def show
    render
  end

  def download
    path = @cur_task.create_entity_log_sites_zip(@cur_user, request.base_url)
    send_file path, type: SS::MimeType.find("zip", "application/zip"), filename: ::File.basename(path),
      disposition: :attachment, x_sendfile: true
  end
end
