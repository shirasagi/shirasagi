class Gws::Portal::Setting::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Group

  navi_view "gws/portal/main/navi"

  private

  def set_crumbs
    @crumbs << [t('gws/portal.group_portal'), action: :index]
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
    raise "403" unless Gws::Portal::GroupSetting.allowed?(:read, @cur_user, site: @cur_site, only: :other)

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    state = params.dig(:s, :state)

    if @search_params || state == "disabled"
      criteria = @model.unscoped.site(@cur_site)
      criteria = criteria.state(state)
      # criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(@search_params)
      criteria = criteria.reorder(name: 1, order: 1, id: 1)
      @items = criteria.page(params[:page]).per(SS.max_items_per_page)
      @component = nil
    else
      @items = nil
      @component = Gws::Portal::GroupTreeComponent.new(cur_site: @cur_site)
    end
  end
end
