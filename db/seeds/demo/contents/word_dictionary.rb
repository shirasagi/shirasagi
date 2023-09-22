puts "# word_dictionary"

def save_word_dictionary(data)
  puts data[:name]
  cond = { site_id: @site.id, name: data[:name] }

  body_file = data.delete(:body_file)
  data[:body] = ::File.read(body_file)

  item = Cms::WordDictionary.find_or_initialize_by cond
  puts item.errors.full_messages unless item.update data
  item
end

save_word_dictionary name: "機種依存文字", body_file: "#{Rails.root}/db/seeds/cms/word_dictionary/dependent_characters.txt"

@site.editor_css_path = '/css/ckeditor_contents.css'
@site.update!
