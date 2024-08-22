class Lsorg::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Lsorg::Node::Page

  navi_view "lsorg/main/navi"

  private

  def redirect_url
    { action: :show, id: @item.id }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "lsorg/page" }
  end
end
