class Chorg::ResultsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :filter_permission
  before_action :set_revision
  before_action :set_crumbs
  before_action :set_item

  model Chorg::Task

  navi_view "cms/main/conf_navi"

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

  def set_item
    criteria = Chorg::Task.site(@cur_site)
    criteria = criteria.and_revision(@cur_revision)
    criteria = criteria.where(name: "chorg:#{params[:type]}_task")
    @item = criteria.order_by(created: -1).first_or_create
  end

  public

  def show
    render
  end

  def show_site

  end

  def interrupt
    @item.update_attributes interrupt: 'stop'
    respond_to do |format|
      format.html { redirect_to({ action: :show }, { notice: t('ss.tasks.interrupted') }) }
      format.json { head :no_content }
    end
  end

  def reset
    @item.destroy
    respond_to do |format|
      format.html { redirect_to({ action: :show }, { notice: t('ss.notice.deleted') }) }
      format.json { head :no_content }
    end
  end
end
