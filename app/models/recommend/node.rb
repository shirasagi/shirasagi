module Recommend::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^recommend\//) }
  end

  class Receiver
    include Cms::Model::Node
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "recommend/receiver") }
  end
end
