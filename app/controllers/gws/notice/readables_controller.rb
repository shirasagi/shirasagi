class Gws::Notice::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_selected_group
  before_action :set_categories
  before_action :set_category
  before_action :set_items
  before_action :set_item, only: [:show]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_selected_group
    if params[:group].present? && params[:group] != '-'
      @selected_group = @cur_site.descendants.active.where(id: params[:group]).first
    end

    @selected_group ||= @cur_site
    @selected_group
  end

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), action: :index]
  end

  def set_categories
    @categories ||= Gws::Notice::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category].blank? || params[:category] == '-'
    @category ||= @categories.find(id: params[:category])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_items
    @items = @model.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).
      search(params[:s])

    if @selected_group != @cur_site
      @items = @items.search(cur_site: @cur_site, group: @selected_group)
    end

    if @category.present?
      @items = @items.search(category: @category.id)
    end
  end

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.page(params[:page]).per(50)
  end
end
