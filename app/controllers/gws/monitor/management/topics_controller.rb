class Gws::Monitor::Management::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
      :show, :edit, :update, :delete, :destroy,
      :close, :open, :download
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_topics_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_topics_path]
    end
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    current_category_id = super
    if @category.present?
      current_category_id[:category_ids] = [ @category.id ]
    end
    current_category_id
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if params[:s] && params[:s][:state] == "closed"
      @items = @items.and_closed.allow(:read, @cur_user, site: @cur_site)
    else
      @items = @items.and_public.readable(@cur_user, @cur_site)
    end

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    @items = @items.search(params[:s]).
        custom_order(params.dig(:s, :sort) || 'updated_desc').
        page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render file: "/gws/monitor/management/main/show_#{@item.mode}"
  end

  def close
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'closed')
  end

  def open
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(article_state: 'open')
  end

  def download
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    csv = @item.to_csv.
        encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "monitor_#{Time.zone.now.to_i}.csv"
  end
end
