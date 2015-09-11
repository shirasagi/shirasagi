module Board
  class Initializer
    Cms::Node.plugin "board/post"

    Cms::Role.permission :read_board_posts
    Cms::Role.permission :edit_board_posts
    Cms::Role.permission :delete_board_posts
  end
end
