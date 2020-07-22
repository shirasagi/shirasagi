class Sns::Apis::UserFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::UserFile

  private

  def fix_params
    h = { cur_user: @cur_user }
    h[:unnormalize] = true if params[:unnormalize].present?
    h
  end

  public

  def select
    select_with_clone
  end
end
