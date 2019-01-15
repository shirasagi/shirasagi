class Opendata::PublicEntityDataset
  include Cms::Model::Page
  include Cms::Addon::GroupPermission

  set_permission_name "opendata_public_entity_datasets", :edit
end
