# 権限判定用モデル
class Opendata::PublicEntityDataset
  include Cms::SitePermission

  set_permission_name "other_opendata_public_entity_datasets", :edit
end
