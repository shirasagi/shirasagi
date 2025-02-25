class Gws::Affair2::Leave::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter
  include Gws::Affair2::WorkflowFilter

  model Gws::Affair2::Leave::File

  before_action :set_state

  navi_view "gws/affair2/attendance/main/navi"

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/leave/file'), gws_affair2_leave_files_main_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    # 既定の管理グループは所属グループと上位グループ
    if @cur_superior_groups.present?
      @set_default_groups = (@cur_superior_groups + [@cur_group]).uniq(&:id)
    end

    # 既定の管理ユーザーは自身と上司
    if @cur_superior_users.present?
      @set_default_users = (@cur_superior_users + [@cur_user]).uniq(&:id)
    end

    super
  end

  def set_state
    @state = params[:state]
  end

  public

  def index
    @items = @model.site(@cur_site)

    case @state
    when "mine"
      @items = @items.user(@cur_user)
      #criteria.where( target_user_id: user.id )
    when "approve"
      @items = @items.where(
        workflow_state: 'request',
        workflow_approvers: { '$elemMatch' => { 'user_id' => @cur_user.id, 'state' => 'request' } })
    when "all"
      @items = @items.allow(:read, @cur_user, site: @cur_site)
    else
      @items = @items.none
    end

    @items = @items.search(params[:s])
  end

  def show
    # 閲覧権限(所有)を考慮しない
    render
  end
end
