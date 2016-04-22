module Gws::Board
  class Initializer
    Gws::GroupSetting.plugin Gws::Board::GroupSetting, ->{ gws_board_setting_path }

    Gws::Role.permission :read_other_gws_board_posts, module_name: 'gws/board'
    Gws::Role.permission :read_private_gws_board_posts, module_name: 'gws/board'
    Gws::Role.permission :edit_other_gws_board_posts, module_name: 'gws/board'
    Gws::Role.permission :edit_private_gws_board_posts, module_name: 'gws/board'
    Gws::Role.permission :delete_other_gws_board_posts, module_name: 'gws/board'
    Gws::Role.permission :delete_private_gws_board_posts, module_name: 'gws/board'

    Gws::Role.permission :read_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :read_private_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :edit_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :edit_private_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :delete_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :delete_private_gws_board_categories, module_name: 'gws/board'
  end
end
