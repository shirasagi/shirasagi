FactoryGirl.define do
  factory :event_page, class: Event::Page, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "event/page"
  end
end
