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
    @aggregation_groups = @aggregation_groups.class.new([])
    @aggregation_groups << @aggregation_group if @aggregation_group
  end

  def set_items
    @items = @model.create_settings(@year, @users, site_id: @cur_site.id, group_id: @group.id).
      search(params[:s]).to_a
    return if allowed_all?

    if allowed_manage?
      user_ids = @users.map(&:id)
      @items = @items.select { |item| user_ids.include?(item.user_id) }
    elsif allowed_use?
      @items = @items.select { |item| item.user_id == @cur_user.id }
    else
      @items = []
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

  def find_item
    set_items
    @item = @items.find { |item| item.id == @item.id }
    raise "404" unless @item
  end

  public

  def index
    set_items
  end

  def show
    find_item
    render
  end

  def edit
    find_item
    render
  end

  def update
    find_item
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end
end
