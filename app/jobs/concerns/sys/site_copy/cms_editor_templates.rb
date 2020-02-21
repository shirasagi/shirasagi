module Sys::SiteCopy::CmsEditorTemplates
  extend ActiveSupport::Concern

  def copy_cms_editor_template(src_item)
    model = Cms::EditorTemplate
    dest_item = nil
    options = copy_cms_editor_template_options
    id = cache(:editor_templates, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = copy_basic_attributes(src_item, model)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      dest_item.attributes = resolve_unsafe_references(src_item, model)
      dest_item.save!

      options[:after].call(src_item) if options[:after]
    end

    dest_item ||= model.site(@dest_site).find(id) if id
    dest_item
  rescue => e
    @task.log("#{src_item.name}(#{src_item.id}): テンプレートのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_editor_templates
    cms_templates_ids = Cms::EditorTemplate.where(site_id: @src_site.id).order_by(updated: 1).pluck(:id)
    cms_templates_ids.each do |src_template_id|
      src_template = Cms::EditorTemplate.find(src_template_id) rescue nil
      next if src_template.blank?
      copy_cms_editor_template(src_template)
    end
  end

  def resolve_editor_template_reference(id)
    cache(:editor_templates, id) do
      src_item = Cms::EditorTemplate.site(@src_site).find(id) rescue nil
      if src_item.blank?
        Rails.logger.warn("#{id}: 参照されているテンプレートが存在しません。")
        return nil
      end

      dest_item = copy_cms_editor_template(src_item)
      dest_item.try(:id)
    end
  end

  private

  def copy_cms_editor_template_options
    {
      before: method(:before_copy_cms_template),
      after: method(:after_copy_cms_template)
    }
  end

  def before_copy_cms_template(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): テンプレートのコピーを開始します。")
  end

  def after_copy_cms_template(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): テンプレートをコピーしました。")
  end
end
