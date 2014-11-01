module Ads::Node
  class Banner
    include Cms::Node::Model

    default_scope ->{ where(route: "ads/banner") }
  end
end
