module Gws::Share
  class Initializer
    Gws::Role.permission :read_other_gws_share_files
    Gws::Role.permission :read_private_gws_share_files
    Gws::Role.permission :edit_other_gws_share_files
    Gws::Role.permission :edit_private_gws_share_files
    Gws::Role.permission :delete_other_gws_share_files
    Gws::Role.permission :delete_private_gws_share_files
  end
end
