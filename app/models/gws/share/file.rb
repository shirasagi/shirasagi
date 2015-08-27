class Gws::Share::File
  include SS::Model::File
  include SS::Reference::User
  include Gws::Share::Reference::Group
  include Gws::Addon::GroupPermission

  default_scope ->{ where(model: "share/file") }
end
