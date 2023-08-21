module Gws::Board::BaseFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_mode
    before_action :set_category
    before_action :set_parent
    before_action :set_crumbs
  end

  ALLOWED_MODES = %w(readable editable trash).freeze

  private

  def set_mode
    @mode = ALLOWED_MODES.include?(params[:mode]) ? params[:mode] : 'readable'
  end

  def set_category
    @categories = Gws::Board::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort

    if category_id = params[:category].presence
      @category ||= Gws::Board::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def set_parent
    @topic  = Gws::Board::Topic.find(params[:topic_id]) if params[:topic_id].present?
    @parent = Gws::Board::Post.find(params[:parent_id]) if params[:parent_id].present?
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_board_label || t("modules.gws/board"), gws_board_topics_path(mode: '-', category: '-')]
    if Gws::Board::Topic.allowed?(:read, @cur_user, site: @cur_site)
      @crumbs << [t("ss.navi.#{@mode}"), gws_board_topics_path(category: '-')]
    end
    @crumbs << [@category.name, gws_board_topics_path] if @category.present?
  end
end
