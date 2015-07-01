class Cms::Apis::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model Cms::File

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def select
      select_with_clone
    end
end
