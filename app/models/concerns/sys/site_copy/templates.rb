module Sys::SiteCopyTemplates
  private
#テンプレート:OK
    def self.copy_templates(site_old, site)
      cms_templates = Cms::EditorTemplate.where(site_id: site_old.id)
      cms_templates.each do |cms_template|
        new_cms_template = Cms::EditorTemplate.new
        new_cms_template = cms_template.dup
        new_cms_template.site_id = site.id
        new_cms_template.save
      end
    end
end