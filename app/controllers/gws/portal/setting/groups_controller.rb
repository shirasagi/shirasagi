class Gws::Portal::Setting::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Group

  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/group"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    super
    raise "403" unless Gws::Group.site(@cur_site).include?(@item)
  end

  public

  def index
    raise "403" unless Gws::Portal::GroupSetting.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).
      state(params.dig(:s, :state))

    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end
end
