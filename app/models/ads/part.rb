module Ads::Part
  class Banner
    include Cms::Model::Part
    include Ads::Addon::PageList

    default_scope ->{ where(route: "ads/banner") }
  end
end
