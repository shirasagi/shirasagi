module Sys::SiteCopy::CmsPages
  private
#固定ページ:OK
    def self.copy_cms_pages(site_old, site)
      cms_pages = Cms::Page.where(site_id: site_old.id, route: "cms/page")
      cms_pages.each do |cms_page|
        new_cms_page = Cms::Page.new
        new_cms_page = cms_page.dup
        new_cms_page.site_id = site.id
        new_cms_page.save
      end
    end
end