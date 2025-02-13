FactoryBot.define do
  factory :event_part_calendar, class: Event::Part::Calendar, traits: [:cms_part] do
    route { "event/calendar" }
  end

  factory :event_part_search, class: Event::Part::Search, traits: [:cms_part] do
    route { "event/search" }
    cur_node { create(:article_node_page, cur_site: cur_site) }
    # filename do
    #   if cur_node
    #     next "#{cur_node.filename}/#{unique_id}.part.html"
    #   end
    #
    #   master_node = create(:article_node_page, cur_site: cur_site)
    #   create(:event_node_search, cur_site: cur_site, cur_node: master_node)
    #   "#{master_node.filename}/#{unique_id}.part.html"
    # end

    after(:create) do |part|
      criteria = Event::Node::Search.site(part.cur_site)
      criteria = criteria.and_public
      criteria = criteria.where(filename: /^#{::Regexp.escape(part.parent.filename)}/, depth: part.depth)
      unless criteria.first
        create(:event_node_search, cur_site: part.cur_site, cur_node: part.parent)
      end
    end
  end
end
