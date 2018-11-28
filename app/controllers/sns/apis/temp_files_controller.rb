class Sns::Apis::TempFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::TempFile

  private

  def fix_params
    h =  { cur_user: @cur_user }
    h[:unnormalize] = true if params[:unnormalize].present?
    h
  end
end
