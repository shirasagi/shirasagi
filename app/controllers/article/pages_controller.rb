class Article::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Article::Page

  append_view_path "app/views/cms/pages"
  navi_view "article/main/navi"
  menu_view "cms/pages/menu"

  public
    def download
      csv = @items.site(@cur_site).order_by(_id:1).to_csv
      send_data csv.encode("SJIS"), filename: "article_pages_#{Time.zone.now.to_i}.csv"
    end
 
    def import
      return if request.get?
 
      @item = @model.new get_params
      @item.cur_site = @cur_site
      result = @item.import
      flash.now[:notice] = t("views.notice.saved") if !result && @item.imported > 0
      render_create result, location: {action: :index}, render: {file: :import}
    end

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  #public
    # Cms::PageFilter
end
