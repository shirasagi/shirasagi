module Sys::SiteCopy::SourceCleanerTemplates
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_source_cleaner_template(src_item)
    model = Cms::SourceCleanerTemplate
    dest_item = nil
    options = copy_source_cleaner_template_options

    id = cache(:source_cleaner_templates, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = source_cleaner_template_attributes(src_item)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end
  end

  def copy_source_cleaner_templates
    model = Cms::SourceCleanerTemplate
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_source_cleaner_template(item)
    end
  end

  def source_cleaner_template_attributes(src_item)
    {
      name: src_item.name,
      order: src_item.order,
      state: src_item.state,
      target_type: src_item.target_type,
      target_value: src_item.target_value,
      action_type: src_item.action_type,
      replaced_value: src_item.replaced_value
    }
  end

  private

  def copy_source_cleaner_template_options
    {
      before: method(:before_copy_source_cleaner_template),
      after: method(:after_copy_source_cleaner_template)
    }
  end
  
  def before_copy_source_cleaner_template(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): ソースクリーナーテンプレートのコピーを開始します。")
  end
  
  def after_copy_source_cleaner_template(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): ソースクリーナーテンプレートをコピーしました。")
  end 
end
