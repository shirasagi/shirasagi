# 権限判定用モデル
class Cms::GenerateLock
  include Cms::SitePermission

  set_permission_name "cms_generate_lock"
end
