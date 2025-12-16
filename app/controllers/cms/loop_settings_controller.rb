class Cms::LoopSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::LoopSetting

  navi_view "cms/main/conf_navi"

  private

  def search_params
    # params[:s] が無い場合でも、必ず permit 済み Parameters を返す
    # (Rails 8 では未permitの Parameters を to_h すると例外になる)
    params.fetch(:s, ActionController::Parameters.new).permit(:html_format, :setting_type, :keyword)
  end

  def set_crumbs
    @crumbs << [t('mongoid.models.cms/loop_setting'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    s = search_params.to_h.symbolize_keys
    @s = @model::SearchForm.from(s)
    @items = @model.site(@cur_site).
      search(s).
      page(params[:page]).per(50)
  end
end
