class Cms::LoopSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::LoopSetting

  navi_view "cms/main/conf_navi"

  private

  def search_params
    params.require(:s).permit(:html_format, :loop_html_setting_type, :keyword).tap do |s|
      # 検索条件の正規化:
      # - 検索フォームの初期値は template
      # - shirasagi は template 固定
      s[:loop_html_setting_type] = 'template' if s[:html_format] == 'shirasagi'
      s[:loop_html_setting_type] = 'template' if s[:loop_html_setting_type].nil?
    end
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
    @s = OpenStruct.new(s)

    @items = @model.site(@cur_site).
      search(s).
      page(params[:page]).per(50)
  end
end
