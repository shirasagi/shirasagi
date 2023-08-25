class Gws::DailyReport::UserReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::DailyReport::ReportFilter

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_cur_month
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.individual"), action: :index]
  end

  def set_items
    set_search_params
    @items ||= @model.site(@cur_site).
      without_deleted.
      and_month(@cur_month).
      and_user(@user || @cur_user).
      and_groups([@cur_group]).
      search(@s)
  end

  def set_item
    set_items

    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end

    @cur_form ||= @item.form if @item.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    if params[:action] == 'show'
      redirect_to gws_daily_report_user_reports_path
      return
    end
    raise e
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  public

  def download
    set_items

    filename = "daily_report_user_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    options = { group: @cur_group, month: @cur_month, encoding: "UTF-8" }
    send_enum(
      @items.user_csv(site: @cur_site, user: @cur_user, options: options),
      type: "text/csv; charset=#{options[:encoding]}", filename: filename
    )
  end
end
