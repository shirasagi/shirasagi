class Cms::LoopSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::LoopSetting

  navi_view "cms/main/conf_navi"

  private

  def search_params
    params.require(:s).permit(:html_format, :setting_type, :keyword)
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new
  end

  def set_crumbs
    @crumbs << [t('mongoid.models.cms/loop_setting'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    @s = OpenStruct.new(search_params.to_h)
    s = @s.to_h
    @items = @model.site(@cur_site).
      search(s).
      page(params[:page]).per(50)
  end
end
