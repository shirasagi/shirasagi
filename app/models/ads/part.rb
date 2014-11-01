module Ads::Part
  class Banner
    include Cms::Part::Model

    default_scope ->{ where(route: "ads/banner") }
  end
end
