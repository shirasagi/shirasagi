class Cms::Line::StatisticsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Statistic

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_statistics"), cms_line_statistics_path]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  public

  def update
    @item.update_statistics
    render_update true, notice: I18n.t('ss.notice.updated')
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    csv = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site).enum_csv(encoding: "UTF-8")
    send_enum csv, type: 'text/csv; charset=UTF-8',
      filename: "cms_line_statistics_#{Time.zone.now.strftime("%Y%m%d_%H%M")}.csv"
  end
end
