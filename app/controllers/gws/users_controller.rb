class Gws::UsersController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter

  prepend_view_path "app/views/sys/users"

  model Gws::User

  private
    def set_crumbs
      @crumbs << [:"sys.user", gws_users_path]
    end
end
