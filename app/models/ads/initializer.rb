module Ads
  class Initializer
    Cms::Node.plugin "ads/banner"
    Cms::Part.plugin "ads/banner"

    Cms::Role.permission :read_other_ads_banners
    Cms::Role.permission :read_private_ads_banners
    Cms::Role.permission :edit_other_ads_banners
    Cms::Role.permission :edit_private_ads_banners
    Cms::Role.permission :delete_other_ads_banners
    Cms::Role.permission :delete_private_ads_banners
  end
end
