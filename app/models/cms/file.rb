class Cms::File
  include SS::Model::File
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  default_scope ->{ where(model: "cms/file") }
end
