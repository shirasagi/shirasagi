module Event::Part
  class Calendar
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/calendar") }
  end

  class Search
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/search") }

    def search_url
      search_path = Event::Node::Search.where(:route => self.route).first.filename
      search_url = "/#{search_path}/"
      search_url
    end

    def cate_ids
      Event::Node::Search.where(:route => self.route).first.parent.st_category_ids
    end
  end
end
