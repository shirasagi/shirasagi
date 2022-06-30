FactoryBot.define do
  factory :event_page, class: Event::Page, traits: [:cms_page] do
    filename { unique_id }
    route { "event/page" }

    event_name { unique_id }
    event_recurrences do
      event_date = Time.zone.today + rand(1..10).days
      [ { kind: "date", start_at: event_date, frequency: "daily", until_on: event_date } ]
    end

    schedule { "schedule-#{unique_id}" }
    venue { "venue-#{unique_id}" }
    content { "content-#{unique_id}" }
    related_url { "http://#{unique_id}.example.jp/#{unique_id}/" }
    cost { "cost-#{unique_id}" }
    contact { "contact-#{unique_id}" }

    ical_link { unique_url }

    factory :event_page_basename_invalid do
      basename { "pa/ge.html" }
    end

    factory :event_page_10_characters_name do
      name { "a" * 10 }
    end

    factory :event_page_100_characters_name do
      name { "b" * 100 }
    end

    factory :event_page_1000_characters_name do
      name { "c" * 1000 }
    end
  end
end
