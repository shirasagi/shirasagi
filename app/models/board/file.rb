class Board::File
  include SS::Model::File
  include SS::UserPermission

  default_scope ->{ where(model: "board/post") }
end
