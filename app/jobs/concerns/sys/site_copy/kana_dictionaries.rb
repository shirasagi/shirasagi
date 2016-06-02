module Sys::SiteCopy::KanaDictionaries
  extend ActiveSupport::Concern

  def copy_kana_dictionaries
    src_dictionaries = Kana::Dictionary.where(site_id: @src_site.id).order_by(updated: 1)
    src_dictionaries.each do |src_dictionary|
      begin
        Rails.logger.debug("#{src_dictionary.name}(#{src_dictionary.id}): 辞書のコピーを開始します。")
        dest_dictionary = Kana::Dictionary.new src_dictionary.attributes.except(:id, :_id, :site_id, :created, :updated)
        dest_dictionary.cur_site = @dest_site
        dest_dictionary.site_id = @dest_site.id
        dest_dictionary.save!
        @task.log("#{src_dictionary.name}(#{src_dictionary.id}): 辞書をコピーしました。")
      rescue => e
        @task.log("#{src_dictionary.name}(#{src_dictionary.id}): 辞書 のコピーに失敗しました。")
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
