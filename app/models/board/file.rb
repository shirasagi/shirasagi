class Board::File
  include SS::Model::File
  include SS::UserPermission
  include Cms::Lgwan::File

  default_scope ->{ where(model: "board/post") }
end
