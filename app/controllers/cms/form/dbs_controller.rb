class Cms::Form::DbsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::FormDb
  navi_view "cms/form/main/navi"

  private

  def set_crumbs
    @crumbs << [Cms::FormDb.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_items
    @items = @model.site(@cur_site)
      .allow(:read, @cur_user, site: @cur_site)
      .order(order: 1)
  end
end
