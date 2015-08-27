class Gws::User
  include SS::Model::User
  include Gws::Addon::Role
  include Gws::Reference::Role
  include Gws::Permission
end
