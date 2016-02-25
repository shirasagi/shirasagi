class Chorg::ResultsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :filter_permission

  before_action :set_revision

  model Job::Log

  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"chorg.revision", controller: :revisions, action: :index]
    end

    def filter_permission
      raise "403" unless Chorg::Revision.allowed?(:edit, @cur_user, site: @cur_site)
    end

    def set_revision
      @revision = Chorg::Revision.find(params[:rid])
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
