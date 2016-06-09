module Sys::SiteCopy::CmsEditorTemplates
  extend ActiveSupport::Concern

  def copy_cms_editor_templates
    cms_templates = Cms::EditorTemplate.where(site_id: @src_site.id).order_by(updated: 1)
    cms_templates.each do |src_template|
      begin
        Rails.logger.debug("#{src_template.name}(#{src_template.id}): テンプレートのコピーを開始します。")
        attr = src_template.attributes.except(:_id, :id, :site_id, :thumb_id, :created, :updated)
        dest_template = Cms::EditorTemplate.new attr
        dest_template.cur_site = @dest_site
        dest_template.site_id = @dest_site.id
        dest_template.thumb_id = resolve_file_reference(src_template.thumb_id) if src_template.thumb_id
        dest_template.save!
        @task.log("#{src_template.name}(#{src_template.id}): テンプレートをコピーしました。")
      rescue => e
        @task.log("#{src_template.name}(#{src_template.id}): テンプレートのコピーに失敗しました。")
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
