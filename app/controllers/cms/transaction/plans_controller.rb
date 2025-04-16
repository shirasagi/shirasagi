class Cms::Transaction::PlansController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Transaction::Plan

  navi_view "cms/main/navi"

  private

  def set_crumbs
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
