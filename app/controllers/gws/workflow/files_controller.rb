class Gws::Workflow::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::File

  private
    def set_crumbs
      @crumbs << [:"modules.gws/workflow", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, state: 'closed' }
    end

  public
    def index
      @items = @model.site(@cur_site).
        readable(@cur_user, @cur_site).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item.readable?(@cur_user)
      render
    end
end
