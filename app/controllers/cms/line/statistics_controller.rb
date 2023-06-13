class Cms::Line::StatisticsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Statistic

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_statistics"), cms_line_statistics_path]
  end

  public

  def update
    @item.update_statistics
    render_update true
  end
end
