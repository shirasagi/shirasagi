FactoryBot.define do
  factory :cms_image_resize, class: Cms::ImageResize do
    state { %w(enabled disabled).sample }
    max_width { rand(800..900) }
    max_height { max_width }
    size { rand(1..9) * 1_024 * 1_024 }
    quality { [ 25, 40, 55, 60, 85 ].sample }
  end
end
