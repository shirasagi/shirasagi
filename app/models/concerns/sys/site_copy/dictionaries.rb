module Sys::SiteCopy::Dictionaries
  extend ActiveSupport::Concern

  private
    #かな辞書:OK
    def copy_dictionaries
      kana_dictionaries = Kana::Dictionary.where(site_id: @site_old.id).order('updated ASC')
      kana_dictionaries.each do |kana_dictionary|
        new_kana_dictionary = Kana::Dictionary.new kana_dictionary.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_kana_dictionary.site_id = @site.id
        begin
          new_kana_dictionary.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
      end
    end
end
