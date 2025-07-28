module Sys::SiteCopy::TranslateTextCaches
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_translate_text_cache(src_item)
    model = ::Translate::TextCache
    dest_item = nil
    options = copy_translate_text_cache_options

    id = cache(:translate_text_caches, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = translate_text_cache_attributes(src_item)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end
  end

  def copy_translate_text_caches
    model = ::Translate::TextCache
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_translate_text_cache(item)
    end
  end

  def translate_text_cache_attributes(src_item)
    {
      api: src_item.api,
      update_state: src_item.update_state,
      text: src_item.text,
      original_text: src_item.original_text,
      source: src_item.source,
      target: src_item.target
    }
  end

  private

  def copy_translate_text_cache_options
    {
      before: method(:before_copy_translate_text_cache),
      after: method(:after_copy_translate_text_cache)
    }
  end
  
  def before_copy_translate_text_cache(src_item)
    Rails.logger.debug("#{src_item.api}(#{src_item.id}): テキストキャッシュのコピーを開始します。")
  end
  
  def after_copy_translate_text_cache(src_item)
    @task.log("#{src_item.api}(#{src_item.id}): テキストキャッシュをコピーしました。")
  end 
end
