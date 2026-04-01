class Gws::Workload::OvertimesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter

  model Gws::Workload::Overtime

  navi_view "gws/workload/main/navi"

  helper_method :allowed_use?, :allowed_manage?, :allowed_all?

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t("gws/workload.tabs.overtime"), url_for(action: :index) ]
  end

  def dropdowns
    %w(year group)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_selected_group
    if allowed_all?
      super
      return
    end

    if params[:group] != "-"
      redirect_to(group: "-")
      return
    end

    super
    if @aggregation_group
      @aggregation_groups = @aggregation_groups.class.new([@aggregation_group])
    else
      @aggregation_groups = @aggregation_groups.class.new([])
    end
  end

  def set_items
    @items ||= begin
      set_year
      set_aggregation_groups
      set_selected_group

      items = @model.all
      items = items.create_settings(@year, @users, site_id: @cur_site.id, group_id: @group.id)
      items = items.search(params[:s])
      if allowed_all?
        # nothing to do
      elsif allowed_manage?
        user_ids = @users.map(&:id)
        items = items.in(user_id: user_ids)
      elsif allowed_use?
        items = items.where(user_id: @cur_user.id)
      else
        items = @model.none
      end
      items
    end
  end

  def allowed_use?
    allowed_manage? || @model.allowed?(:use, @cur_user, site: @cur_site)
  end

  def allowed_manage?
    allowed_all? || @model.allowed?(:manage, @cur_user, site: @cur_site)
  end

  def allowed_all?
    @model.allowed?(:all, @cur_user, site: @cur_site)
  end

  public

  def index
    set_items
  end

  def show
    render
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end
end
