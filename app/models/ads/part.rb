module Ads::Part
  class Banner
    include Cms::Part::Model
    include Ads::Addon::BannerSetting

    default_scope ->{ where(route: "ads/banner") }
  end
end
