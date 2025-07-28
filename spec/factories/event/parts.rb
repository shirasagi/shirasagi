FactoryBot.define do
  factory :event_part_calendar, class: Event::Part::Calendar, traits: [:cms_part] do
    route { "event/calendar" }
  end

  factory :event_part_search, class: Event::Part::Search, traits: [:cms_part] do
    route { "event/search" }
    # 本パーツには親フォルダーが必要で、
    # 親フォルダーは public_sort_options を実装している必要がある（event/addon/page_list が組み込まれていなければならない）。
    # 親フォルダーとして event_node_page は不可。
    cur_node { create(:article_node_page, cur_site: cur_site) }

    after(:create) do |part|
      # 兄弟にフォルダー event/search が必要
      criteria = Event::Node::Search.site(part.cur_site)
      criteria = criteria.and_public
      criteria = criteria.where(filename: /^#{::Regexp.escape(part.parent.filename)}/, depth: part.depth)
      unless criteria.first
        create(:event_node_search, cur_site: part.cur_site, cur_node: part.parent)
      end
    end
  end
end
