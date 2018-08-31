FactoryBot.define do
  factory :faq_page, class: Faq::Page, traits: [:cms_page] do
    filename { unique_id }
    route "faq/page"

    factory :faq_page_basename_invalid do
      basename "pa/ge.html"
    end

    factory :faq_page_10_characters_name do
      name "a" * 10
    end

    factory :faq_page_100_characters_name do
      name "b" * 100
    end

    factory :faq_page_1000_characters_name do
      name "c" * 1000
    end
  end
end
