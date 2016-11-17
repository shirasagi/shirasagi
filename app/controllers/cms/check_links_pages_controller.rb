class Cms::CheckLinksPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Page::CheckLinks
  menu_view  "cms/check_links_contents/menu"
  navi_view  "cms/check_links_contents/navi"
  append_view_path "app/views/cms/check_links_contents"

  public
    def index
      @items = @model.site(@cur_site).search(params[:s])
      @items = @items.select { |item| item.allowed?(:read, @cur_user, site: @cur_site) }
      @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
    end
end
