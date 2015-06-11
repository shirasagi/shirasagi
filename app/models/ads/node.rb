module Ads::Node
  class Banner
    include Cms::Model::Node

    default_scope ->{ where(route: "ads/banner") }
  end
end
