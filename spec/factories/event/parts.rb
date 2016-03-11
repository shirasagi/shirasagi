FactoryGirl.define do
  factory :event_part_calendar, class: Event::Part::Calendar, traits: [:cms_part] do
    route "event/calendar"
  end
end
