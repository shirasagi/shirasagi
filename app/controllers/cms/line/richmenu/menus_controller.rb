class Cms::Line::Richmenu::MenusController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Richmenu::Menu

  navi_view "cms/line/main/navi"

  before_action :set_richmenu_group

  private

  def set_crumbs
    @crumbs << [t("cms.line_richmenu"), cms_line_richmenu_groups_path]
    @crumbs << [t("cms.line_richmenu_menu"), cms_line_richmenu_group_menus_path]
  end

  def set_richmenu_group
    @richmenu_group = Cms::Line::Richmenu::Group.site(@cur_site).find(params[:group_id])
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, group: @richmenu_group }
  end

  def set_items
    @items = @richmenu_group.menus
  end

  public

  def crop
    set_item
    return if request.get?

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_update @item.update, render: { template: "crop" }
  end
end
