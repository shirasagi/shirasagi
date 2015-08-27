class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter
  include SS::FileFilter

  model Gws::Share::File

  private
    def fix_params
      { cur_group: @cur_group, cur_user: @cur_user }
    end

  public
    def index
      @items = @model.group(@cur_group).
        order_by(_id: -1).
        page(params[:page]).per(20)
    end
end
