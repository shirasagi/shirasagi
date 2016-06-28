class Gws::Workflow::RoutesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::Route

  prepend_view_path "app/views/workflow/routes"
  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"workflow.name", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless @model.site(@cur_site).include?(@item)
    end
end
