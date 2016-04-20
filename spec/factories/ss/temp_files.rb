FactoryGirl.define do
  factory :ss_temp_file, class: SS::TempFile do
    cur_user { ss_user }
    in_file { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png' }
  end
end
