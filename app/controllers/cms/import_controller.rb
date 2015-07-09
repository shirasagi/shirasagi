class Cms::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Node::ImportNode

  navi_view "cms/main/navi"
  menu_view nil

  public
    def import
      @item = @model.new get_params
      @item.cur_site = @cur_site
      result = @item.save_with_import
      flash.now[:notice] = t("views.notice.saved") if !result && @item.imported > 0
      render_create result, location: redirect_url, render: { file: :index }
    end

  private
    def redirect_url
      cms_import_path(cid: @cur_node)
    end
end
