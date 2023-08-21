FactoryBot.define do
  factory :gws_share_folder, class: Gws::Share::Folder do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end