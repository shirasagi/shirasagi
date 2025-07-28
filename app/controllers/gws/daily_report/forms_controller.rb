class Gws::DailyReport::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Form

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.year ||= @cur_site.fiscal_year
      s
    end
    @years ||= begin
      items = @model.unscoped.site(@cur_site).without_deleted
      years = items.distinct(:year)
      years << @cur_site.fiscal_year
      (years.min..years.max).to_a.reverse
    end
    @groups = Gws::Group.site(@cur_site).active
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      order_by(year: -1, order: 1).
      page(params[:page]).per(50)
  end

  def copy_year
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @src_year = params.dig(:item, :src_year) || @model.site(@cur_site).without_deleted.distinct(:year).max
    @dest_year = params.dig(:item, :dest_year) || (@src_year + 1)

    if request.get? || request.head?
      render
      return
    end

    job = Gws::DailyReport::CopyYearJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(@src_year, @dest_year)

    redirect_to({ action: :index }, { notice: I18n.t('gws/daily_report.notice.copy_year_started') })
  end
end
