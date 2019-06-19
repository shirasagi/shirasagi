FactoryBot.define do
  factory :gws_share_file, class: Gws::Share::File do
    association :folder, factory: :gws_share_folder
    cur_site { gws_site }
    cur_user { gws_user }

    #name { "name-#{unique_id}" }
    in_file Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png'
    category_ids [1]
  end
end
