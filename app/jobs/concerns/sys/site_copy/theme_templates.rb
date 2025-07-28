module Sys::SiteCopy::ThemeTemplates
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_theme_template(src_item)
    model = Cms::ThemeTemplate
    dest_item = nil
    options = copy_theme_template_options

    id = cache(:theme_templates, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = theme_template_attributes(src_item)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end
  end

  def copy_theme_templates
    model = Cms::ThemeTemplate
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_theme_template(item)
    end
  end

  def theme_template_attributes(src_item)
    {
      name: src_item.name,
      class_name: src_item.class_name,
      css_path: src_item.css_path,
      order: src_item.order,
      state: src_item.state,
      default_theme: src_item.default_theme,
      high_contrast_mode: src_item.high_contrast_mode,
      font_color: src_item.font_color,
      background_color: src_item.background_color
    }
  end
  

  private

  def copy_theme_template_options
    {
      before: method(:before_copy_theme_template),
      after: method(:after_copy_theme_template)
    }
  end
  
  def before_copy_theme_template(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): テーマテンプレートのコピーを開始します。")
  end
  
  def after_copy_theme_template(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): テーマテンプレートをコピーしました。")
  end
end
