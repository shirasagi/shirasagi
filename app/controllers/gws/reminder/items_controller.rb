class Gws::Reminder::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::Schedule::PlanHelper

  model Gws::Reminder
  navi_view "gws/reminder/main/navi"
  before_action :set_mode

  private

  def set_mode
    @mode = %w(future all).include?(params[:mode]) ? params[:mode] : 'future'
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_reminder_label || t("mongoid.models.gws/reminder"), action: :index]
  end

  public

  def index
    cond = {}
    cond = { date: { '$gte' => Time.zone.now } } if @mode == 'future'

    @items = @model.site(@cur_site).
      user(@cur_user).
      where(cond).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def redirect
    set_item
    raise "404" if @item.user_id != @cur_user.id
    @item.set(read_at: Time.zone.now)

    redirect_url = @item.url
    if redirect_url
      redirect_to redirect_url
    else
      #
    end
  end
end
