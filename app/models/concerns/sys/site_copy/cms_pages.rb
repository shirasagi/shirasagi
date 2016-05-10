module Sys::SiteCopy::CmsPages
  private
    #固定ページ:OK
    def copy_cms_pages
      cms_pages = Cms::Page.where(site_id: @site_old.id, route: "cms/page")
      cms_pages.each do |cms_page|
        cms_page = cms_page.becomes_with_route
        new_cms_page = cms_page.class.new cms_page.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_page.site_id = @site.id
        new_cms_page.layout_id = @layout_records_map[cms_page.layout_id]
        begin
          new_cms_page.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end
end
