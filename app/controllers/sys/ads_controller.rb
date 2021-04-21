class Sys::AdsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Setting

  menu_view "sys/crud/resource_menu"

  before_action :set_addons, only: %w(show new create edit update)

  private

  def set_crumbs
    @crumbs << [t("sys.ad"), { action: :show }]
  end

  def set_item
    @item = @model.find_or_create_by({})
  end

  def set_addons
    @addons = @item.addons(:ad)
  end
end
