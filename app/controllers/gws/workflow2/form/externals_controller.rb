class Gws::Workflow2::Form::ExternalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::Form::External

  navi_view "gws/workflow2/main/navi"

  helper_method :categories_in_order, :purposes_in_order, :category_filter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t('modules.gws/workflow2'), gws_workflow2_setting_path]
    @crumbs << [t("gws/workflow2.navi.form.external"), url_for(action: :index)]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def categories_in_order(item = nil)
    @categories_in_order ||= begin
      criteria = Gws::Workflow2::Form::Category.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)
      criteria.to_a
    end

    return @categories_in_order unless item

    @categories_in_order.lazy.select { |cate| item.category_ids.include?(cate.id) }
  end

  def purposes_in_order(item)
    @purposes_in_order ||= begin
      criteria = Gws::Workflow2::Form::Purpose.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1, name: 1)
      criteria.to_a
    end

    @purposes_in_order.lazy.select { |cate| item.purpose_ids.include?(cate.id) }
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

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      if category_filter.present?
        s[:category_criteria] = category_filter.to_mongoid_criteria
      else
        s[:category_criteria] = nil
      end
      s
    end
  end

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    set_search_params

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50)
  end
end
