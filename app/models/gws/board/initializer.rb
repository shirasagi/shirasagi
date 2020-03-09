module Gws::Board
  class Initializer
    Gws::Role.permission :use_gws_board, module_name: 'gws/board'

    Gws::Role.permission :read_other_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :read_private_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :edit_other_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :edit_private_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :delete_other_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :delete_private_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :trash_other_gws_board_topics, module_name: 'gws/board'
    Gws::Role.permission :trash_private_gws_board_topics, module_name: 'gws/board'

    Gws::Role.permission :read_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :read_private_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :edit_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :edit_private_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :delete_other_gws_board_categories, module_name: 'gws/board'
    Gws::Role.permission :delete_private_gws_board_categories, module_name: 'gws/board'

    Gws.module_usable :board do |site, user|
      Gws::Board.allowed?(:use, user, site: site)
    end
  end
end
