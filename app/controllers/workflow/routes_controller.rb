class Workflow::RoutesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Workflow::Route

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("workflow.name"), action: :index]
  end

  def set_item
    super
    raise "403" unless @model.site(@cur_site).include?(@item)
  end
end
