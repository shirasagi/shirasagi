FactoryGirl.define do
  factory :key_visual_image, class: KeyVisual::Image, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "key_visual/image"
    link_url "/example/"
    in_file { Fs::UploadedFile.create_from_file "#{Rails.root}/spec/fixtures/ss/logo.png", content_type: 'image/png' }
  end
end
