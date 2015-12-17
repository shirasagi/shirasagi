class Gws::Workflow::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::File

  private
    def set_crumbs
      @crumbs << [:"modules.gws/workflow", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, state: 'closed' }
    end
end
