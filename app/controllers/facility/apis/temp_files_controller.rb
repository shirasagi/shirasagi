class Facility::Apis::TempFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::TempFile
  self.only_image = true

  private

  def fix_params
    { cur_user: @cur_user, state: "public" }
  end
end
