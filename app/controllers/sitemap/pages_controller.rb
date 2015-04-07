class Sitemap::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Sitemap::Page

  append_view_path "app/views/cms/pages"
  navi_view "sitemap/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def export_urls
      @item = @model.new get_params
      @item.site_id = @cur_site.id

      render plain: @item.load_sitemap_urls.join("\n")
    end
end
