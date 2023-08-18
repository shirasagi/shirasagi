# 権限判定用モデル
class Cms::Tool
  include Cms::SitePermission

  set_permission_name "cms_tools", :use
end
