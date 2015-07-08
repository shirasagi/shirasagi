FactoryGirl.define do
  factory :key_visual_part_slide, class: KeyVisual::Part::Slide, traits: [:cms_part] do
    route "key_visual/slide"
  end
end
