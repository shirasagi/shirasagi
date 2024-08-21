class Gws::Workflow2::SelectFormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::Form::Base

  navi_view "gws/workflow2/main/navi"

  before_action :set_search_params
  helper_method :mode, :url_for_index, :categories, :categories_in_order, :category_filter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t("modules.gws/workflow2"), action: :index]
  end

  def mode
    @mode ||= params[:mode].to_s.presence || "by_keyword"
  end

  def url_for_index(category:, exclude: false)
    s = @s.to_h
    s.delete(:cur_site)

    category_ids = Array(s[:category_ids])
    category_ids = category_ids.dup if category_ids.equal?(s[:category_ids])
    if exclude
      category_ids.delete(category.id)
    else
      category_ids << category.id
      category_ids.sort!
      category_ids.uniq!
    end
    if category_ids.present?
      s[:category_ids] = category_ids
    else
      s.delete(:category_ids)
    end

    url_for(action: :index, s: s)
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      if s[:category_ids].is_a?(Array)
        s[:category_ids].select!(&:numeric?)
        s[:category_ids].map!(&:to_i)
      end
      if category_filter.present?
        s[:category_criteria] = category_filter.to_mongoid_criteria
      else
        s[:category_criteria] = nil
      end
      s.keyword_operator ||= "and"
      s
    end
  end

  def categories
    @categories ||= begin
      criteria = Gws::Workflow2::Form::Category.all.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)
      criteria.to_a
    end
  end

  def categories_in_order(item)
    categories.lazy.select { |cate| item.category_ids.include?(cate.id) }
  end

  def category_filter
    @category_filter ||= begin
      filter = Gws::CategoryFilter.new(
        cur_site: @cur_site, cur_user: @cur_user, category_model: Gws::Workflow2::Form::Category)
      base64_filter = params.dig(:s, :category_filter)
      filter.base64_filter = base64_filter if base64_filter.present? && base64_filter != "-"
      filter
    end
  end

  public

  def index
    if @s.keyword.blank? && @s.category_ids.blank? && @s.purpose_id.blank? && mode != "by_keyword"
      render "cover"
      return
    end

    @items = @model.site(@cur_site)
    @items = @items.and_public
    @items = @items.readable(@cur_user, site: @cur_site)
    @items = @items.search(@s)
    @items = @items.order_by(order: 1, name: 1)
    @items = @items.page(params[:page]).per(50)
    render
  end
end
