# 権限判定用モデル
class Cms::SnsPost
  include Cms::SitePermission

  set_permission_name "cms_page_sns_posts", :use
end
