FactoryBot.define do
  trait :cms_part do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id.to_s }
    filename { "#{unique_id}.part.html" }
    route { "cms/free" }
  end

  factory :cms_part, class: Cms::Part, traits: [:cms_part] do
    mobile_view { :show }
  end

  factory :cms_part_base, class: Cms::Part::Base, traits: [:cms_part] do
    route { "cms/base" }
  end

  factory :cms_part_free, class: Cms::Part::Free, traits: [:cms_part] do
    route { "cms/free" }

    factory :cms_part_free_basename_invalid do
      basename { "pa/rt" }
    end
  end

  factory :cms_part_node, class: Cms::Part::Node, traits: [:cms_part] do
    route { "cms/node" }
  end

  factory :cms_part_node2, class: Cms::Part::Node2, traits: [:cms_part] do
    route { "cms/node2" }
  end

  factory :cms_part_page, class: Cms::Part::Page, traits: [:cms_part] do
    route { "cms/page" }
  end

  factory :cms_part_tabs, class: Cms::Part::Tabs, traits: [:cms_part] do
    route { "cms/tabs" }
  end

  factory :cms_part_crumb, class: Cms::Part::Crumb, traits: [:cms_part] do
    route { "cms/crumb" }
  end

  factory :cms_part_sns_share, class: Cms::Part::Crumb, traits: [:cms_part] do
    route { "cms/sns_share" }
  end

  factory :cms_part_calendar_nav, class: Cms::Part::CalendarNav, traits: [:cms_part] do
    route { "cms/calendar_nav" }
  end

  factory :cms_part_monthly_nav, class: Cms::Part::MonthlyNav, traits: [:cms_part] do
    route { "cms/monthly_nav" }
    periods { rand(16..24) }
  end

  factory :cms_part_site_search_keyword, class: Cms::Part::SiteSearchKeyword, traits: [:cms_part] do
    route { "cms/site_search_keyword" }
  end

  factory :cms_part_print, class: Cms::Part::Print, traits: [:cms_part] do
    route { "cms/print" }
  end

  factory :cms_part_clipboard_copy, class: Cms::Part::ClipboardCopy, traits: [:cms_part] do
    route { "cms/clipboard_copy" }
  end

  factory :cms_part_site_search_history, class: Cms::Part::SiteSearchHistory, traits: [:cms_part] do
    route { "cms/site_search_history" }
  end

  factory :cms_part_history_list, class: Cms::Part::HistoryList, traits: [:cms_part] do
    route { "cms/history_list" }
  end

  factory :cms_part_form_search, class: Cms::Part::FormSearch, traits: [:cms_part] do
    route { "cms/form_search" }
    column_name { unique_id }
    column_kind { %w(any_of start_with end_with all).sample }
  end
end
