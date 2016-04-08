class Gws::Apis::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter
  include SS::AjaxFileFilter

  model Gws::Share::File

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def select
      select_with_clone
    end
end
