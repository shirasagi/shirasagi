module PublicBoard
  class Initializer
    Cms::Node.plugin "public_board/post"

    Cms::Role.permission :read_board_posts
    Cms::Role.permission :edit_board_posts
    Cms::Role.permission :delete_board_posts
  end
end
