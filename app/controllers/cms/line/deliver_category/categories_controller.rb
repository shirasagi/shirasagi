class Cms::Line::DeliverCategory::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::DeliverCategory::Base

  navi_view "cms/line/main/navi"

  before_action :set_parent

  private

  def set_parent
    @parent = @model.site(@cur_site).find(params[:deliver_category_id])
    @model = @parent.class
  end

  def set_crumbs
    set_parent
    @crumbs << [t("cms.line_deliver_category"), cms_line_deliver_categories_path]
    @crumbs << [@parent.name, { action: :index }]
  end

  def set_items
    @items = @parent.children
  end

  def pre_params
    { parent: @parent }
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, parent: @parent }
  end
end
