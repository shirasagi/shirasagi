class Chat::IntentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chat::Intent

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t('chat.bot'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
