module Gws
  class Initializer
    Gws::Role.permission :read_gws_users
    Gws::Role.permission :edit_gws_users
  end
end
