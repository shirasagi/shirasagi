class SS::File
  include SS::Model::File
  include SS::Relation::Thumb

  has_many_thumbs
end
