class Board::File
  include SS::Model::File
  include SS::UserPermission
  include SS::Relation::Thumb

  default_scope ->{ where(model: "board/post") }
end
