module Faq::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^faq\//) }
  end

  class Page
    include Cms::Node::Model
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "faq/page") }
  end

  class Search
    include Cms::Node::Model
    include Cms::Addon::PageList
    include Category::Addon::Setting

    default_scope ->{ where(route: "faq/search") }

    public
      def condition_hash
        conditions.present? ? super : {}
      end
  end
end
