class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::FileFilter

  model Gws::Share::File

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
