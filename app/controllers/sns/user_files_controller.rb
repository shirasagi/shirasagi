class Sns::UserFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter

  model SS::UserFile

  private

  def set_crumbs
    @crumbs << [t("sns.file"), params.include?(:user) ? sns_user_files_path : sns_cur_user_files_path]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def index
    cond = (@cur_user.id != @sns_user.id) ? { state: :public } : { }

    @items = @model.user(@sns_user).
      where(cond).
      order_by(_id: -1).
      page(params[:page]).per(20)
  end
end
