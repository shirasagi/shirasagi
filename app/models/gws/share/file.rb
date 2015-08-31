class Gws::Share::File
  include SS::Model::File
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  default_scope ->{ where(model: "share/file") }

  def remove_public_file
    #TODO: fix SS::Model::File
  end
end
