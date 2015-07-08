FactoryGirl.define do
  factory :key_visual_image, class: KeyVisual::Image, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "key_visual/image"
    link_url "/example/"
    file_id 1
  end
end
