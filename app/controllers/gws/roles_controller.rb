class Gws::RolesController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter

  prepend_view_path "app/views/ss/roles"

  model Gws::Role

  private
    def set_crumbs
      @crumbs << [:"cms.role", action: :index]
    end
end
