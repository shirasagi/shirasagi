FactoryBot.define do
  trait :cms_page do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "#{unique_id}.html" }
    route { "cms/page" }
    released_type { "fixed" }
  end

  factory :cms_page, class: Cms::Page, traits: [:cms_page] do
    factory :cms_page_basename_invalid do
      basename { "pa/ge.html" }
    end

    factory :cms_page_10_characters_name do
      name { "a" * 10 }
    end

    factory :cms_page_100_characters_name do
      name { "b" * 100 }
    end

    factory :cms_page_1000_characters_name do
      name { "c" * 1000 }
    end
  end

  factory :cms_import_page, class: Cms::ImportPage, traits: [:cms_page] do
    route { "cms/import_page" }
  end
end
