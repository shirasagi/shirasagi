FactoryBot.define do
  factory :gws_bookmark_folder, class: Gws::Bookmark::Folder do
    cur_site { gws_site }
    cur_user { gws_user }

    in_basename { unique_id }
    in_parent { gws_user.bookmark_root_folder(gws_site).id }
  end
end
