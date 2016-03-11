FactoryGirl.define do
  factory :event_page, class: Event::Page, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "event/page"
    event_name { unique_id }
    event_dates { [Time.zone.now] }
  end
end
