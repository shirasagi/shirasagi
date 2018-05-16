module Sys::SiteCopy::CmsLoopSettings
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_loop_setting(src_item)
    model = Cms::LoopSetting
    dest_item = nil
    options = copy_cms_loop_setting_options
    id = cache(:loop_settings, src_item.id) do
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
    @task.log("#{src_item.name}(#{src_item.id}): ループHTMLのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_loop_settings
    model = Cms::LoopSetting
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_cms_loop_setting(item)
    end
  end

  def resolve_loop_setting_reference(id)
    cache(:loop_settings, id) do
      src_item = Cms::LoopSetting.site(@src_site).find(id) rescue nil
      if src_item.blank?
        Rails.logger.warn("#{id}: 参照されているループHTMLが存在しません。")
        return nil
      end

      dest_item = copy_cms_loop_setting(src_item)
      dest_item.try(:id)
    end
  end

  private

  def copy_cms_loop_setting_options
    {
      before: method(:before_copy_cms_loop_setting),
      after: method(:after_copy_cms_loop_setting)
    }
  end

  def before_copy_cms_loop_setting(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): ループHTMLのコピーを開始します。")
  end

  def after_copy_cms_loop_setting(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): ループHTMLをコピーしました。")
  end
end
