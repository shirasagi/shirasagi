FactoryGirl.define do
  trait :cms_page do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name { "#{unique_id}" }
    filename { "#{name}.html" }
    route "cms/page"
  end

  factory :cms_page, class: Cms::Page, traits: [:cms_page] do
    #
  end
end
