class Sns::User::TempFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include Sns::FileFilter
  include SS::AjaxFilter

  model SS::TempFile

  private
    def fix_params
      { cur_user: @cur_user }
    end

  public
    def index
      @items = @model.user(@cur_user).
        order_by(_id: -1).
        page(params[:page]).per(20)
    end

    def select
      set_item
      render layout: !request.xhr?
    end
end
