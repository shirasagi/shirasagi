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
    @item.cur_site = @cur_site
    @item.site = @cur_site

    service = Sitemap::RenderService.new(cur_site: @cur_site, cur_node: @cur_node, page: @item)
    render plain: service.load_whole_contents.map(&:url).join("\n")
  end
end
