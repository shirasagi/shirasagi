class Gws::Workload::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter
  include Gws::Workload::GroupFilter
  include Gws::Workload::WorkFilter

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t("gws/workload.tabs.admin"), url_for(action: :index) ]
  end

  def dropdowns
    %w(year group user)
  end

  def set_items
    @items = @model.site(@cur_site).only_deleted
    @items = @items.allow(:trash, @cur_user, site: @cur_site)
    @items = @items.member(@user) if @user
    @items = @items.member_group(@group) if @group
    @items = @items.search(@s).
      page(params[:page]).per(50).
      custom_order(params.dig(:s, :sort) || 'due_date')
  end

  public

  def show
    raise "403" if !@item.allowed?(:trash, @cur_user, site: @cur_site)
    render
  end
end
