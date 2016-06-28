# 権限判定用モデル
class Cms::Editor
  include Cms::SitePermission

  set_permission_name "cms_editors"
end
