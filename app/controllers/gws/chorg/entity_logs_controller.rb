class Gws::Chorg::EntityLogsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :filter_permission
  before_action :set_revision
  before_action :set_crumbs
  before_action :set_task

  model Gws::Chorg::Task

  navi_view 'gws/main/conf_navi'
  menu_view 'chorg/entity_logs/menu'
  append_view_path 'app/views/chorg/entity_logs'

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), controller: :revisions, action: :index]
    @crumbs << [@cur_revision.name, gws_chorg_revision_path(id: @cur_revision.id)]
  end

  def filter_permission
    raise "403" unless Gws::Chorg::Revision.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_revision
    @cur_revision = Gws::Chorg::Revision.find(params[:rid])
    raise "403" unless @cur_revision.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  def set_task
    criteria = Gws::Chorg::Task.site(@cur_site)
    criteria = criteria.and_revision(@cur_revision)
    criteria = criteria.where(name: "gws:chorg:#{params[:type]}_task")
    @cur_task = criteria.order_by(created: -1).first_or_create
  end

  public

  def index
    @items = @cur_task.entity_logs
    @items ||= []
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
  end

  def show
    render
  end
end
