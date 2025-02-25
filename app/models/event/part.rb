module Event::Part
  class Calendar
    include Cms::Model::Part
    include Event::Addon::Calendar
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/calendar") }
  end

  # パーツ "event/search" を適切に構成するのは難しい
  #
  # 改善点1
  # まず、親フォルダーは public_sort_options を実装している必要がある。つまり親フォルダーは event/addon/page_list が組み込まれていなければならない。
  # しかし、ノード "event/page" には event/addon/page_list が組み込まれていない。
  # 直観的にはノード "event/page" の下にパーツ "event/search" を配置すれば良さそうだがそうではない。
  #
  # 改善点2
  # 親か兄弟にノード "event/search" が必要。
  # ノード "event/search" には、event/addon/page_list が組み込まれているので、親とするのは問題ない。
  class Search
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/search") }

    def find_search_node
      # first, look parent
      parent = self.parent
      return parent if parent.route == 'event/search'

      # second, lookup siblings node
      Event::Node::Search.site(self.site).and_public.
        where(filename: /^#{::Regexp.escape(parent.filename)}/, depth: self.depth).first
    end

    def search_url
      find_search_node.try(:url)
    end

    def cate_ids
      find_search_node.parent.st_category_ids
    end
  end
end
