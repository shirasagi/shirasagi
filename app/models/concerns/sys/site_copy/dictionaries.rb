module Sys::SiteCopy::Dictionaries
  extend ActiveSupport::Concern

  private
    #かな辞書:OK
    def copy_dictionaries
      kana_dictionaries = Kana::Dictionary.where(site_id: @site_old.id)
      kana_dictionaries.each do |kana_dictionary|
        new_kana_dictionary = Kana::Dictionary.new
        new_kana_dictionary = kana_dictionary.dup
        new_kana_dictionary.site_id = @site.id
        new_kana_dictionary.save
      end
    end
end