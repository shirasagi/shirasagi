# 権限判定用モデル
class Cms::EditorExtension
  include Cms::SitePermission

  set_permission_name "cms_editor_extensions"
end
