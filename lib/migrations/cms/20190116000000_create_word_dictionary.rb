class SS::Migration20190116000000
  WORD_DICTIONARY_NAME = '機種依存文字'.freeze

  def change
    body = ::File.read("#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt")
    Cms::Site.all.pluck(:id).each do |id|
      Cms::WordDictionary.create(
        name: WORD_DICTIONARY_NAME, body: body, site_id: id
      )
    end
  end
end
