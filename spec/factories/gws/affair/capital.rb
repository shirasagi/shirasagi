FactoryBot.define do
  factory :gws_affair_capital, class: Gws::Affair::Capital do
    cur_site { gws_site }
    cur_user { gws_user }

    article_code { 1 }
    section_code { 2 }
    subsection_code { 3 }
    item_code { 4 }
    subitem_code { 5 }
    project_code { 6 }
    detail_code { 7 }

    project_name { "事業名称" }
    description_name { "説明名称" }
    item_name { "節名称" }
    subitem_name { "細節名称" }
  end
end
