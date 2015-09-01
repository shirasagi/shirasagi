module Gws
  class Initializer
    Gws::Role.permission :edit_gws_users
    Gws::Role.permission :read_other_gws_facilities
    Gws::Role.permission :read_private_gws_facilities
    Gws::Role.permission :edit_other_gws_facilities
    Gws::Role.permission :edit_private_gws_facilities
    Gws::Role.permission :delete_other_gws_facilities
    Gws::Role.permission :delete_private_gws_facilities
  end
end
