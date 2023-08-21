class Sys::PasswordPoliciesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Setting

  menu_view "sys/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("sys.password_policy"), { action: :show }]
  end

  def set_item
    @item = @model.find_or_create_by({})
  end
end
