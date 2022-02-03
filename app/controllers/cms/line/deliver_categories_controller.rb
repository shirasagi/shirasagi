class Cms::Line::DeliverCategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::DeliverCategory::Base

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_deliver_category"), cms_line_deliver_categories_path]
  end

  def set_model
    @addons = []
    return super if params[:action] != "create"

    type = params.dig(:item, :type)
    @model = "Cms::Line::DeliverCategory::#{type.classify}".constantize
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def set_items
    super
    @items = @items.and_root
  end
end
