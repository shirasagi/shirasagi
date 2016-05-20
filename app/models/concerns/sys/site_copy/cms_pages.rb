module Sys::SiteCopy::CmsPages
  private
    #固定ページ:OK
    def copy_cms_pages
      cms_pages = Cms::Page.where(site_id: @site_old.id, route: "cms/page").order_by(updated: 1)
      cms_pages.each do |cms_page|
        cms_page = cms_page.becomes_with_route
        new_cms_page = cms_page.class.new cms_page.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_page.site_id = @site.id
        new_cms_page.layout_id = @layout_records_map[cms_page.layout_id]

        unless new_cms_page.file_ids.empty?
          file_ids = []
          new_cms_page.file_ids.each do |source_file_id|
            dest_file = copy_attach_file source_file_id
            file_ids.push(dest_file.id)
          end
          new_cms_page.file_ids = file_ids
        end

        begin
          new_cms_page.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end

    def copy_attach_file(source_file_id)
      source_file = SS::File.where(id: source_file_id).one
      dest_file = SS::File.new source_file.attributes.except(:id, :_id, :site_id, :created, :updated)
      dest_file.in_file = source_file.uploaded_file
      dest_file.site_id = @site.id
      begin
        dest_file.save!
      rescue => exception
        Rails.logger.error(exception.message)
        throw exception
      end
      dest_file
    end
end
