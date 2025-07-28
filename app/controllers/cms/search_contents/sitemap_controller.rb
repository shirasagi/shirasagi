class Cms::SearchContents::SitemapController < ApplicationController
  include Cms::BaseFilter

  before_action :check_permission
  navi_view "cms/search_contents/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.search_contents"), cms_search_contents_pages_path]
    @crumbs << [t("cms.search_contents_sitemap"), action: :index]
  end

  def check_permission
    raise "403" if SS.config.cms.cms_sitemap.blank?
    raise "403" if SS.config.cms.cms_sitemap['disable'].present?
    raise "403" unless Cms::Sitemap.allowed?(:use, @cur_user, site: @cur_site)
  end

  public

  def download_all
    respond_to do |format|
      format.html
      format.csv do
        response.status = 200
        send_enum Cms::FolderSize.enum_csv(@cur_site),
          type: 'text/csv; charset=Shift_JIS',
          filename: "folder_sizes_#{Time.zone.now.to_i}.csv"
      end
    end
  end
end
