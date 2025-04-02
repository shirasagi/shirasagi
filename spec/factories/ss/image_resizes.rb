FactoryBot.define do
  factory :ss_image_resize, class: SS::ImageResize do
    name { unique_id }
    order { rand(10..20) }
    state { %w(enabled disabled).sample }
    max_width { rand(800..900) }
    max_height { max_width }
    quality { [ 25, 40, 55, 60, 85 ].sample }
    size { rand(1..9) * 1_024 * 1_024 }
  end
end
