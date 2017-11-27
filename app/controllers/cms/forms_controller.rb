class Cms::FormsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Form
  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [Cms::Form.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  public

  def column_form
    set_item
  end
end
