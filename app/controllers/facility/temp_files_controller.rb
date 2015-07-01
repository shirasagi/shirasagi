class Facility::TempFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter
  include SS::AjaxFilter

  model Facility::TempFile

  private
    def fix_params
      { cur_user: @cur_user, state: "public" }
    end

  public
    def index
      @items = @model.user(@cur_user).
        order_by(_id: -1).
        page(params[:page]).per(20)
    end

    def select
      set_item
      render file: :select, layout: !request.xhr?
    end
end
