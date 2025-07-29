module Gws::CategoryFrame
  extend ActiveSupport::Concern

  included do
    include Gws::ApiFilter

    before_action :set_frame_id

    helper_method :categories, :simple_activated?, :advanced_activated?, :simple_mode?, :simple_selected?, :return_path
    helper_method :category_frame_options, :url_for_simple, :url_for_advanced, :url_for_category_decide
    helper_method :advanced_overall_operator_all?, :advanced_overall_operator_any?, :advanced_each_filter, :advanced_each_category

    layout "ss/item_frame"
  end

  private

  def append_view_paths
    append_view_path "app/views/gws/category_frame"
    super
  end

  def set_frame_id
    @frame_id = "gws-category-navi-dialog"
  end

  def categories
    @categories ||= begin
      @model.site(@cur_site).readable(@cur_user, site: @cur_site)
    end
  end

  def category_filter
    @category_filter ||= begin
      filter = Gws::CategoryFilter.new(
        cur_site: @cur_site, cur_user: @cur_user, category_model: @model, categories: categories)
      filter.base64_filter = category_param if category_param.present? && category_param != '-'
      filter
    end
  end

  def category_frame_options
    return @category_frame_options if instance_variable_defined?(:@category_frame_options)

    unless params.key?("gws/category_frame")
      return @category_frame_options = {}
    end

    @category_frame_options = params.require("gws/category_frame").permit(:only, :mode, :return_path, :action_btn)
  end

  def simple_activated?
    category_frame_options[:only].blank? || category_frame_options[:only].to_s == "simple"
  end

  def advanced_activated?
    category_frame_options[:only].blank? || category_frame_options[:only].to_s == "advanced"
  end

  def mode
    return @mode if instance_variable_defined?(:@mode)

    if category_frame_options.key?(:mode)
      if advanced_activated? && category_frame_options[:mode].to_s == "advanced"
        @mode = "advanced"
      else
        @mode = "simple"
      end
    else
      # auto-detect
      if advanced_activated? && category_filter.advanced?
        @mode = "advanced"
      else
        @mode = "simple"
      end
    end
  end

  def simple_mode?
    simple_activated? && mode == "simple"
  end

  def selected_categories_set
    return @selected_categories_set if instance_variable_defined?(:@selected_categories_set)

    if category_filter.present?
      @selected_categories_set = Set.new(category_filter.selected_categories)
    else
      @selected_categories_set = []
    end
  end

  def simple_selected?(cate)
    selected_categories_set.include?(cate)
  end

  def advanced_overall_operator_all?
    return true if category_filter.blank?
    return true if category_filter.overall_operator_all?
    false
  end

  def advanced_overall_operator_any?
    !advanced_overall_operator_all?
  end

  def advanced_each_filter(&block)
    return if category_filter.blank?
    category_filter.each_filter(&block)
  end

  def advanced_each_category(category_ids, &block)
    categories.in(id: category_ids).reorder(order: 1, name: 1).each_with_index(&block)
  end

  def url_for_simple
    url_for(
      action: :index,
      "gws/category_frame" => {
        mode: 'simple', return_path: return_path, action_btn: category_frame_options[:action_btn].to_s.presence
      })
  end

  def url_for_advanced
    url_for(
      action: :index,
      "gws/category_frame" => {
        mode: 'advanced', return_path: return_path, action_btn: category_frame_options[:action_btn].to_s.presence
      })
  end

  public

  def index
    render
  end
end
