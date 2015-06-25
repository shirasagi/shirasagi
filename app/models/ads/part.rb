module Ads::Part
  class Banner
    include Cms::Model::Part
    include Ads::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ads/banner") }
  end
end
