FactoryGirl.define do
  trait :cms_page do
    site_id { cur_site ? cur_site.id : cms_site.id }
    user_id { cur_user ? cur_user.id : cms_user.id }
    name { unique_id.to_s }
    filename { "#{unique_id}.html" }
    route "cms/page"
  end

  factory :cms_page, class: Cms::Page, traits: [:cms_page] do
    #
  end

  factory :cms_import_page, class: Cms::ImportPage, traits: [:cms_page] do
    route "cms/import_page"
  end
end
