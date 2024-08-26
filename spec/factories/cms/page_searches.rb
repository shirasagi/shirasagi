FactoryBot.define do
  factory :cms_page_search, class: Cms::PageSearch do
    cur_site { cms_site }
    cur_user { cms_user }
    name { "name-#{unique_id}" }
    order { rand(10..20) }
  end

  factory :cms_page_search_full, class: Cms::PageSearch do
    cur_site { cms_site }
    cur_user { cms_user }
    name { "name-#{unique_id}" }
    order { rand(10..20) }

    # cms/addon/page_search
    search_name { "name-#{unique_id}" }
    search_filename { "filename-#{unique_id}" }
    search_keyword { "keyword-#{unique_id}" }
    search_category_ids { Array(3).new { rand(1..100) }.uniq }
    search_group_ids { Array(3).new { rand(1..100) }.uniq }
    search_user_ids { Array(3).new { rand(1..100) }.uniq }
    search_node_ids { Array(3).new { rand(1..100) }.uniq }
    search_routes { Cms::Page.routes.sample[:route] }
    search_released_condition { %w(absolute relative).sample }
    search_released_start { 4.days.ago }
    search_released_close { 2.days.ago }
    search_released_after { rand(1..10) }
    search_updated_condition { %w(absolute relative).sample }
    search_updated_start { 4.days.ago }
    search_updated_close { 2.days.ago }
    search_updated_after { rand(1..10) }
    search_created_condition { %w(absolute relative).sample }
    search_created_start { 4.days.ago }
    search_created_close { 2.days.ago }
    search_created_after { rand(1..10) }
    search_state { %w(public closed ready closing).sample }
    search_first_released { %w(draft published).sample }
    search_approver_state { %w(request approve remand).sample }
    search_sort { [ "name", "filename", "created", "updated -1", "released -1", "approved -1" ].sample }
  end
end
