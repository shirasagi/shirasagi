module Sys::SiteCopy::Templates
  extend ActiveSupport::Concern

  private
    #テンプレート:OK
    def copy_templates
      copy_template_thumbnails
      cms_templates = Cms::EditorTemplate.where(site_id: @site_old.id).order('updated ASC')
      cms_templates.each do |cms_template|
        new_cms_template = Cms::EditorTemplate.new cms_template.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_template.site_id = @site.id
        if cms_template.thumb_id
          source_thumbnail = SS::File.where(id: cms_template.thumb_id).one
          dest_thumbnail = SS::File.where(site_id: @site.id, filename: source_thumbnail.filename).one
          new_cms_template.thumb_id = dest_thumbnail._id
        end
        begin
          new_cms_template.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end

    def copy_template_thumbnails
      SS::File.where(site_id: @site_old.id, model: 'cms/editor_template').each do |source_template_thumbnail|
        dest_template_thumbnail = SS::File.new source_template_thumbnail.attributes.
            except(:id, :_id, :site_id, :created, :updated)
        dest_template_thumbnail.in_file = source_template_thumbnail.uploaded_file
        dest_template_thumbnail.site_id = @site.id
        dest_template_thumbnail.save!
      end
    end
end
