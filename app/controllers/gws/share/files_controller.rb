class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
