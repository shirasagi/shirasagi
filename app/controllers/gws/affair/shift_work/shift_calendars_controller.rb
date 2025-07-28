class Gws::Affair::ShiftWork::ShiftCalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter

  model Gws::Affair::ShiftCalendar

  navi_view "gws/affair/main/navi"

  before_action :deny
  before_action :set_groups
  before_action :set_user, except: :index
  before_action :set_item, only: [:delete, :destroy]
  helper_method :group_options, :editable_shift_record?

  private

  # シフト勤務機能は利用停止
  def deny
    raise "403"
  end

  def set_user
    @user = Gws::User.find(params[:user])
  end

  def get_params
    fix_params
  end

  def pre_params
    { cur_site: @cur_site, user: @user }
  end

  def fix_params
    { cur_site: @cur_site, user: @user }
  end

  def editable_shift_record?
    %i[manage_private manage_all].find { |priv| Gws::Affair::ShiftRecord.allowed?(priv, @cur_user, site: @cur_site) }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/shift_work/shift_calendar"), gws_affair_shift_work_shift_calendars_path ]
  end

  def set_groups
    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_private, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_group).active
    else
      @groups = Gws::Group.none
    end

    @group = @groups.to_a.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @cur_group
  end

  def group_options
    @groups.map { |g| [g.name, g.id] }
  end

  public

  def index
    @users = Gws::User.active.in(group_ids: [@group.id]).order_by_title(@cur_site)
  end

  def new
    raise "403" unless editable_shift_record?
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise "403" unless editable_shift_record?
    @item = @model.new get_params
    render_create @item.save, location: { action: :index, group_id: @group.id }
  end

  def delete
    raise "403" unless editable_shift_record?
    render
  end

  def destroy
    raise "403" unless editable_shift_record?
    render_destroy @item.destroy, location: { action: :index, group_id: @group.id }
  end
end
