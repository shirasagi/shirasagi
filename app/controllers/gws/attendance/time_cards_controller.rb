class Gws::Attendance::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  before_action :set_cur_month
  before_action :set_items, only: %i[index enter leave]
  before_action :set_item, only: %i[enter leave]

  private

  def set_crumbs
    @crumbs << [t('modules.gws/attendance'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { in_year: @cur_month.year, in_month: @cur_month.month }
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_items
    @items ||= @model.site(@cur_site).
      user(@cur_user).
      allow(:use, @cur_user, site: @cur_site).
      search(params[:s])
  end

  def set_item
    @cur_month
    @item = @items.find_by(year_month: @cur_month)
  end

  public

  def index
    set_items
    @items = @items.
      page(params[:page]).per(50)
    @item = @items.where(year_month: @cur_month).first
  end

  # def show
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render
  # end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
    render_create @item.save, location: { action: :index }
  end

  def download
    # TODO: implementation
    raise NotImplementedError
  end

  def enter
    @now = Time.zone.now
    @cur_date = @now.beginning_of_day
    @item.histories.create(date: @cur_date, action: 'enter')
    record = @item.records.where(date: @cur_date).first_or_create
    record.enter = @now
    render_update record.save, location: { action: :index }
  end

  def leave
    @now = Time.zone.now
    @cur_date = @now.beginning_of_day
    @item.histories.create(date: @cur_date, action: 'leave')
    record = @item.records.where(date: @cur_date).first_or_create
    record.leave = @now
    render_update record.save, location: { action: :index }
  end

  # def edit
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   if @item.is_a?(Cms::Addon::EditLock)
  #     unless @item.acquire_lock
  #       redirect_to action: :lock
  #       return
  #     end
  #   end
  #   render
  # end
  #
  # def update
  #   @item.attributes = get_params
  #   @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render_update @item.update
  # end
  #
  # def delete
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render
  # end
  #
  # def destroy
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render_destroy @item.destroy
  # end
  #
  # def destroy_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:use, @cur_user, site: @cur_site)
  #       next if item.destroy
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end
  #
  # def disable_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:use, @cur_user, site: @cur_site)
  #       item.attributes = fix_params
  #       next if item.disable
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end
end
