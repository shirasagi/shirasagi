module Sys::SiteCopy::WordDictionaries
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_word_dictionary(src_item)
    model = Cms::WordDictionary
    dest_item = nil
    options = copy_word_dictionary_options

    id = cache(:word_dictionaries, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = word_dictionary_attributes(src_item)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      options[:after].call(src_item) if options[:after]
    end
  end

  def copy_word_dictionaries
    model = Cms::WordDictionary
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_word_dictionary(item)
    end
  end

  def word_dictionary_attributes(src_item)
    {
      name: src_item.name,
      body: src_item.body
    }
  end

  private

  def copy_word_dictionary_options
    {
      before: method(:before_copy_word_dictionary),
      after: method(:after_copy_word_dictionary)
    }
  end
  
  def before_copy_word_dictionary(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): ワード辞書のコピーを開始します。")
  end
  
  def after_copy_word_dictionary(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): ワード辞書をコピーしました。")
  end 
end
