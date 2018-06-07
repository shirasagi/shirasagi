FactoryBot.define do

  factory :gws_memo_folder, class: Gws::Memo::Folder do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    path { "path-#{unique_id}" }
  end
end
