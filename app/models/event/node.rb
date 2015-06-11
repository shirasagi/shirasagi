module Event::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^event\//) }
  end

  class Page
    include Cms::Model::Node
    include Category::Addon::Setting
    include Event::Addon::PageList

    default_scope ->{ where(route: "event/page") }

    public
      def condition_hash
        cond = super
        cond.merge "event_dates.0" => { "$exists" => true }
      end
  end
end
