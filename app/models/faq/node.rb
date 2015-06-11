module Faq::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^faq\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "faq/page") }
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "faq/search") }

    public
      def condition_hash
        conditions.present? ? super : {}
      end
  end
end
