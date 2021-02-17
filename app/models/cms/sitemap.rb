# 権限判定用モデル
class Cms::Sitemap
  include Cms::SitePermission

  set_permission_name "cms_sitemap", :use
end
