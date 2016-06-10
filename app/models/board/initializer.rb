module Board
  class Initializer
    Cms::Node.plugin "board/post"

    Cms::Role.permission :read_board_posts
    Cms::Role.permission :edit_board_posts
    Cms::Role.permission :delete_board_posts

    SS::File.model "board/post", Board::File
  end
end
