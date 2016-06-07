FactoryGirl.define do
  factory :cms_file, class: Cms::File do
    cur_user { cms_user }
    model { "cms/file" }
    in_file { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png' }
  end
end
