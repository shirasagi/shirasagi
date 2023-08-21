class Gws::DailyReport::GroupReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::DailyReport::ReportFilter

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_cur_date
  before_action :set_users
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.department"), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::DailyReport::Form.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.where(year: @cur_site.fiscal_year, daily_report_group_id: @group.id)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_users
    @users = Gws::User.site(@cur_site).
      active.
      readable_users(@cur_user, site: @cur_site).
      where(group_ids: @group.id)
    @users = @users.where(id: @cur_user.id) if @cur_site.fiscal_year(@cur_date) != @cur_site.fiscal_year
  end

  def set_items
    set_search_params
    @items ||= begin
      items = @model.site(@cur_site).without_deleted.and_date(@cur_date).and_groups([@group]).search(@s)
      items = items.and_user(@cur_user) if @cur_site.fiscal_year(@cur_date) != @cur_site.fiscal_year
      items
    end
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
      redirect_to gws_daily_report_group_reports_path
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

  def download_all
    if request.get? || request.head?
      return
    end

    if params[:item].present?
      csv_params = params.require(:item).permit(:encoding, :export_target)
    else
      csv_params = {}
    end
    csv_params.merge!(fix_params)

    set_items

    filename = "daily_report_group_csv_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    options = csv_params.merge({ group: @group })
    send_enum(
      @items.group_csv(site: @cur_site, user: @cur_user, options: options),
      type: "text/csv; charset=#{options[:encoding]}", filename: filename
    )
  end
end
