class Gws::Affair2::Admin::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair2::AttendanceSetting

  navi_view "gws/affair2/admin/main/navi"

  private

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/admin/attendance_setting'), action: :index ]
  end

  def group_ids
    if params[:s].present? && params[:s][:group].present?
      @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
    end
    @group ||= @cur_site
    @group_ids ||= @cur_site.descendants_and_self.active.in_group(@group).pluck(:id)
  end

  public

  def index
    raise "403" unless @model.allowed?(:use, @cur_user, site: @cur_site)

    @groups = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)

    @s = OpenStruct.new(params[:s])
    @s.cur_site = @cur_site

    @items = Gws::User.site(@cur_site).active.
      state(params.dig(:s, :state)).
      in(group_ids: group_ids).
      search(@s).
      order_by_title(@cur_site).
      page(params[:page]).per(50)

    @attendances = {}
    @model.site(@cur_site).in(user_id: @items.pluck(:id)).each do |item|
      @attendances[item.user_id] = item
    end
  end

  def import
    @item = Gws::Affair2::AttendanceSettingImporter.new
    @item.cur_site = @cur_site
    if request.get? || request.head?
      return
    end

    @item.attributes = params.require(:item).permit(:in_file)
    if @item.invalid?
      return
    end
    render_update @item.import, notice: t("ss.notice.imported"), location: { action: :index }, render: { template: :import }
  end

  def download_all
    @item = SS::DownloadParam.new
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    downloader = Gws::Affair2::AttendanceSettingDownloader.new(@cur_site)
    enumerable = downloader.all_enum_csv(encoding: @item.encoding)
    send_enum enumerable, filename: "attendance_settings_#{Time.zone.now.to_i}.csv"
  end

  def download_no_setting
    @item = SS::DownloadParam.new
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    downloader = Gws::Affair2::AttendanceSettingDownloader.new(@cur_site)
    enumerable = downloader.no_setting_enum_csv(encoding: @item.encoding)
    send_enum enumerable, filename: "attendance_settings_#{Time.zone.now.to_i}.csv"
  end
end
