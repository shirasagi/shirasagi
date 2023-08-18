module Gws::Faq::BaseFilter
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
    @categories = Gws::Faq::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort

    if category_id = params[:category].presence
      @category ||= Gws::Faq::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def set_parent
    @topic  = @model.find params[:topic_id] if params[:topic_id].present?
    @parent = @model.find params[:parent_id] if params[:parent_id].present?
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_faq_label || t("modules.gws/faq"), gws_faq_topics_path(mode: '-', category: '-')]
    @crumbs << [t("ss.navi.#{@mode}"), gws_faq_topics_path(category: '-')]
    @crumbs << [@category.name, gws_faq_topics_path] if @category.present?
  end
end
