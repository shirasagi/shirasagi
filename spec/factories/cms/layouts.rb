FactoryGirl.define do
  trait :cms_layout do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name "#{unique_id}"
    filename { "#{name}.layout.html" }
  end

  factory :cms_layout, class: Cms::Layout, traits: [:cms_layout] do
    #
  end
end
