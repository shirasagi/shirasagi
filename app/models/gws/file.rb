class Gws::File
  include SS::Model::File
  include Gws::Reference::Site
  # include SS::Relation::Thumb

  default_scope ->{ where(model: 'gws/file') }
end
