module Event::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^event\//) }
  end

  class Page
    include Cms::Node::Model
    include Event::Addon::PageList
    include Event::Addon::Category::Setting

    default_scope ->{ where(route: "event/page") }

    public
      def condition_hash
        cond = []
        cids = []

        if conditions.present?
          cond << { filename: /^#{filename}\//, depth: depth + 1 }
        else
          cond << {}
        end

        conditions.each do |url|
          node = Cms::Node.filename(url).first
          next unless node
          cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
          cids << node.id
        end
        cond << { :category_ids.in => cids } if cids.present?

        { '$or' => cond }
      end
  end
end
