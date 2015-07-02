class SS::File
  include SS::Model::File
  include SS::Relation::Thumb

  use_relation_thumbs
end
