class Cms::Line::SettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Setting

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_setting"), cms_line_setting_path]
  end

  def set_item
    @item = @model.with_site(@cur_site)
  end
end
