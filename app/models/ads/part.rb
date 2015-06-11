module Ads::Part
  class Banner
    include Cms::Model::Part
    include Cms::Addon::Release
    include Ads::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ads/banner") }
  end
end
