class Cms::ApiTokensController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ApiToken

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t('cms.api_token'), action: :index]
  end

  def pre_params
    { audience: @cur_user }
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end
end
