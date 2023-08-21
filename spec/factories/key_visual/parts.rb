FactoryBot.define do
  factory :key_visual_part_slide, class: KeyVisual::Part::Slide, traits: [:cms_part] do
    route { "key_visual/slide" }
  end

  factory :key_visual_part_swiper_slide, class: KeyVisual::Part::SwiperSlide, traits: [:cms_part] do
    route { "key_visual/swiper_slide" }

    link_target { [ '', '_blank' ].sample }
    kv_speed { rand(200..500) }
    kv_space { rand(0..20) }
    kv_autoplay { %w(disabled enabled started).sample }
    kv_pause { rand(3_000..5_000) }
    kv_navigation { %w(hide show).sample }
    kv_pagination_style { %w(none disc number).sample }
    kv_thumbnail { %w(hide show).sample }
    kv_thumbnail_count { rand(1..5) }
  end
end
