module Ezine::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^ezine\//) }
  end

  class Page
    include Cms::Model::Node
    include Ezine::Addon::Signature
    include Ezine::Addon::SenderAddress
    include Ezine::Addon::Reply

    default_scope ->{ where(route: "ezine/page") }
  end

  class Backnumber
    include Cms::Model::Node
    include Cms::Addon::PageList

    default_scope ->{ where(route: "ezine/backnumber") }

    def condition_hash
      h = super
      h['$or'] << { filename: /^#{parent.filename}\//, depth: self.depth }
      h
    end
  end
end
