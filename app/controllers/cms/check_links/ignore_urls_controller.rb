class Cms::CheckLinks::IgnoreUrlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::IgnoreUrl

  navi_view "cms/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
