FactoryBot.define do
  factory :event_page, class: Event::Page, traits: [:cms_page] do
    filename { unique_id }
    route "event/page"

    event_name { unique_id }
    event_dates { [Time.zone.now.beginning_of_day + rand(1..10).days] }

    schedule { "schedule-#{unique_id}" }
    venue { "venue-#{unique_id}" }
    content { "content-#{unique_id}" }
    related_url { "http://#{unique_id}.example.jp/#{unique_id}/" }
    cost { "cost-#{unique_id}" }
    contact { "contact-#{unique_id}" }

    factory :event_page_basename_invalid do
      basename "pa/ge.html"
    end

    factory :event_page_10_characters_name do
      name "a" * 10
    end

    factory :event_page_100_characters_name do
      name "b" * 100
    end

    factory :event_page_1000_characters_name do
      name "c" * 1000
    end
  end
end
