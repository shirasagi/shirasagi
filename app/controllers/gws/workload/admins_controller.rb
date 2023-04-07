class Gws::Workload::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter
  include Gws::Workload::WorkFilter
  include Gws::Workload::NotificationFilter

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t("gws/workload.tabs.admin"), url_for(action: :index) ]
  end

  def dropdowns
    %w(year group user)
  end

  def pre_params
    today = Time.zone.today
    ret[:due_date] = today + @cur_site.workload_default_due_date.day
    ret[:due_start_on] = today
    ret[:year] = @year if @year
    ret[:category_id] = @category.id if @category

    # work target
    ret[:member_group_id] = @cur_group.id
    ret[:member_group_id] = @group.id if @group
    ret[:member_ids] = [@cur_user.id]
    ret[:member_ids] = [@user.id] if @user

    # readable setting
    @default_readable_setting = proc do
      @item.readable_setting_range = 'select'
      @item.readable_group_ids = [@cur_group.id]
      @item.readable_group_ids << @group.id if @group
    end

    # group permissions
    ret[:group_ids] = [@cur_group.id]
    ret[:group_ids] << @group.id if @group
    ret[:user_ids] = [@cur_user.id]
    ret[:user_ids] << @user.id if @user

    ret
  end

  def set_items
    @items = @model.site(@cur_site).without_deleted
    @items = @items.readable_or_manageable(@cur_user, site: @cur_site)
    @items = @items.member(@user) if @user
    @items = @items.member_group(@group) if @group
    @items = @items.search(@s).
      page(params[:page]).per(50).
      custom_order(params.dig(:s, :sort) || 'due_date')
  end
end
