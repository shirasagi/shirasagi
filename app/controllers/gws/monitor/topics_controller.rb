class Gws::Monitor::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy,
  ]

  before_action :set_selected_items, only: [
      :destroy_all, :public_all,
      :preparation_all, :qNA_all
  ]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [t('modules.gws/monitor'), gws_monitor_topics_path]
  end

  def pre_params
    super.keep_if {|key| %i(facility_ids).exclude?(key)}
  end

  public

  def public
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(state: 'public')
  end

  def preparation
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(state: 'preparation')
  end

  def qNA
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(state: 'qNA')
  end

  def public_all
    raise '403' unless @items.allowed?(:edit, @cur_user, site: @cur_site)
    @items.update_all(state: 'public')
    render_destroy_all(false)
  end

  def preparation_all
    raise '403' unless @items.allowed?(:edit, @cur_user, site: @cur_site)
    @items.update_all(state: 'preparation')
    render_destroy_all(false)
  end

  def qNA_all
    raise '403' unless @items.allowed?(:edit, @cur_user, site: @cur_site)
    @items.update_all(state: 'qNA')
    render_destroy_all(false)
  end
end