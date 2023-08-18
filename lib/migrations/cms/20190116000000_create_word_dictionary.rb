class SS::Migration20190116000000
  include SS::Migration::Base

  depends_on "20181218120000"

  WORD_DICTIONARY_NAME = '機種依存文字'.freeze

  def change
    body = ::File.read("#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt")
    Cms::Site.all.pluck(:id).each do |id|
      item = Cms::WordDictionary.find_or_initialize_by(
        name: WORD_DICTIONARY_NAME, site_id: id
      )
      next if item.persisted?

      item.body = body
      item.save!
    end
  end
end
