class Gws::User
  include SS::Model::User
  include Gws::Addon::Role
  include Gws::Reference::Role
  include Gws::Permission

  embeds_ids :groups, class_name: "Gws::Group"
end
