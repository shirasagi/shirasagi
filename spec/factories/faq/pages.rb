FactoryGirl.define do
  factory :faq_page, class: Faq::Page, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "faq/page"
  end
end
