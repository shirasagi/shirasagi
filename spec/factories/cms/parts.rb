FactoryBot.define do
  trait :cms_part do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "#{unique_id}.part.html" }
    route "cms/free"
  end

  factory :cms_part, class: Cms::Part, traits: [:cms_part] do
    mobile_view :show
  end

  factory :cms_part_base, class: Cms::Part::Base, traits: [:cms_part] do
    route "cms/base"
  end

  factory :cms_part_free, class: Cms::Part::Free, traits: [:cms_part] do
    route "cms/free"

    factory :cms_part_free_basename_invalid do
      basename "pa/rt"
    end
  end

  factory :cms_part_node, class: Cms::Part::Node, traits: [:cms_part] do
    route "cms/node"
  end

  factory :cms_part_page, class: Cms::Part::Page, traits: [:cms_part] do
    route "cms/page"
  end

  factory :cms_part_tabs, class: Cms::Part::Tabs, traits: [:cms_part] do
    route "cms/tabs"
  end

  factory :cms_part_crumb, class: Cms::Part::Crumb, traits: [:cms_part] do
    route "cms/crumb"
  end

  factory :cms_part_sns_share, class: Cms::Part::Crumb, traits: [:cms_part] do
    route "cms/sns_share"
  end

  factory :cms_part_calendar_nav, class: Cms::Part::CalendarNav, traits: [:cms_part] do
    route "cms/calendar_nav"
  end

  factory :cms_part_monthly_nav, class: Cms::Part::MonthlyNav, traits: [:cms_part] do
    route "cms/monthly_nav"
  end
end
