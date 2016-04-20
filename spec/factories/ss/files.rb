FactoryGirl.define do
  factory :ss_file, class: SS::File do
    cur_user { ss_user }
    model { "ss/#{unique_id}" }
    in_file { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png' }
  end
end
