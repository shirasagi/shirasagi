FactoryBot.define do
  factory :cms_temp_file, class: Cms::TempFile do
    cur_user { cms_user }
    site { cms_site }
    in_file { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png' }
  end
end
