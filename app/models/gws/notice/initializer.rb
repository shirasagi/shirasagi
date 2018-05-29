module Gws
  module Notice
    class Initializer
      Gws::Role.permission :read_other_gws_notices
      Gws::Role.permission :read_private_gws_notices
      Gws::Role.permission :edit_other_gws_notices
      Gws::Role.permission :edit_private_gws_notices
      Gws::Role.permission :delete_other_gws_notices
      Gws::Role.permission :delete_private_gws_notices
    end
  end
end
