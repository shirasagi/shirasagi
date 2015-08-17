class PublicBoard::File
  include SS::Model::File
  include SS::UserPermission
  include SS::Relation::Thumb

  default_scope ->{ where(model: "public_board/post") }

  # TODO: add validation for public posted
  private
    #
end
