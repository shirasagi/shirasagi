class Gws::Monitor::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/monitor/settings/navi"

  model Gws::Monitor::Category

  def index
    #raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @search_params = params[:s]
    @search_params = @search_params.delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/monitor/group_setting"), gws_monitor_setting_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end

