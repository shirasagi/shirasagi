FactoryBot.define do
  trait :cms_layout do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "#{unique_id}.layout.html" }
    html { "<html><head></head><body></ yield /></body></html>" }
  end

  factory :cms_layout, class: Cms::Layout, traits: [:cms_layout] do
    #

    factory :cms_layout_basename_invalid do
      basename "lay/out"
    end
  end
end
