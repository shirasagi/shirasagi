module Sys::SiteCopy::Templates
  extend ActiveSupport::Concern

  private
    #テンプレート:OK
    def copy_templates
      cms_templates = Cms::EditorTemplate.where(site_id: @site_old.id)
      cms_templates.each do |cms_template|
        new_cms_template = Cms::EditorTemplate.new cms_template.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_template.site_id = @site.id
        begin
          new_cms_template.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end
end
