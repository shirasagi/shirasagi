module Gws::Board
  class Initializer
    Gws::Role.permission :read_other_gws_board_posts
    Gws::Role.permission :read_private_gws_board_posts
    Gws::Role.permission :edit_other_gws_board_posts
    Gws::Role.permission :edit_private_gws_board_posts
    Gws::Role.permission :delete_other_gws_board_posts
    Gws::Role.permission :delete_private_gws_board_posts
  end
end
