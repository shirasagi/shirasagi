class SS::Migration20150521192401
  include SS::Migration::Base

  depends_on "20150518040533"

  def change
    Cms::Page.all.each do |page|
      if page.site
        page.files.each do |file|
          file.set(site_id: page.site.id) unless file.site_id
        end
      end
    end

    Ads::Banner.all.each do |page|
      if page.site && page.file
        page.file.set(site_id: page.site.id) unless page.file.site_id
      end
    end

    Facility::Image.all.each do |page|
      if page.site && page.image
        page.image.set(site_id: page.site.id) unless page.image.site_id
      end
    end
  end
end
