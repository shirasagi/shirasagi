module Sys::SiteCopy::TranslateLangs
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_translate_lang(src_item)
    model = ::Translate::Lang
    dest_item = nil
    options = copy_translate_lang_options

    id = cache(:translate_langs, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = translate_lang_attributes(src_item)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end
  end

  def copy_translate_langs
    model = ::Translate::Lang
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_translate_lang(item)
    end
  end

  def translate_lang_attributes(src_item)
    {
      name: src_item.name,
      code: src_item.code,
      mock_code: src_item.mock_code,
      google_translation_code: src_item.google_translation_code,
      accept_languages: src_item.accept_languages,
      microsoft_translator_text_code: src_item.microsoft_translator_text_code
    }
  end

  private

  def copy_translate_lang_options
    {
      before: method(:before_copy_translate_lang),
      after: method(:after_copy_translate_lang)
    }
  end
  
  def before_copy_translate_lang(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): 言語のコピーを開始します。")
  end
  
  def after_copy_translate_lang(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): 言語をコピーしました。")
  end 
end
