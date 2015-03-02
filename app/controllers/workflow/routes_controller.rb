class Workflow::RoutesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter

  model Cms::Workflow::Route

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"workflow.name", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless @model.site(@cur_site).include?(@item)
    end
end
