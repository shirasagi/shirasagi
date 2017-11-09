class Gws::Chorg::ResultsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :filter_permission

  before_action :set_revision

  model Gws::Job::Log

  navi_view 'gws/main/conf_navi'
  append_view_path 'app/views/chorg/results'

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), controller: :revisions, action: :index]
  end

  def filter_permission
    raise "403" unless Gws::Chorg::Revision.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_revision
    @revision = Gws::Chorg::Revision.find(params[:rid])
    raise "403" unless @revision.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  public

  def index
    @items = @model.site(@cur_site).
      in(job_id: @revision.job_ids).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end

  def show
    render
  end
end
