FactoryBot.define do
  trait :gws_search_form_target_base do
    cur_site { gws_site }
    name { unique_id }
    place_holder { unique_id }
    search_service { "shirasagi_es" }
  end

  factory :gws_search_form_target, class: Gws::SearchForm::Target, traits: [:gws_search_form_target_base] do
    name { "ポータル全文検索" }
    search_service { "shirasagi_es" }
  end

  factory :gws_search_form_target_external1, class: Gws::SearchForm::Target, traits: [:gws_search_form_target_base] do
    name { "外部サイト全文検索1" }
    search_service { "external" }
    search_url { "http://sample1.example.jp/" }
    search_keyword_name { "q" }
    search_other_query { "num=20" }
  end

  factory :gws_search_form_target_external2, class: Gws::SearchForm::Target, traits: [:gws_search_form_target_base] do
    name { "外部サイト全文検索2" }
    search_service { "external" }
    search_url { "http://sample2.example.jp/" }
    search_keyword_name { "keyword" }
  end
end
