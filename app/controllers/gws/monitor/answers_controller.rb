class Gws::Monitor::AnswersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy,
    :public, :preparation, :qNA
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

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        and_answers().
        page(params[:page]).per(50)
  end

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