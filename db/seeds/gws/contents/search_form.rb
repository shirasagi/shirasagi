puts "# gws/search_form"
puts "\# #{@site.name}"

def create_search_form_target(data)
  create_item(Gws::SearchForm::Target, data)
end

create_search_form_target(
  name: 'サイト内検索', order: 10, place_holder: 'サイト内検索', search_service: 'shirasagi_es', state: 'enabled')
