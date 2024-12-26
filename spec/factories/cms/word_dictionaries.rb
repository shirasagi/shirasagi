FactoryBot.define do
  factory :cms_word_dictionary, class: Cms::WordDictionary do
    cur_site { cms_site }
    name { unique_id.to_s }
    body { File.read("#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt") }
  end
end
