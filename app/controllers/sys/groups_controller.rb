class Sys::GroupsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Group

  menu_view "sys/crud/menu"

  private
    def set_crumbs
      @crumbs << [:"sys.group", sys_groups_path]
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)
      @items = @model.allow(:edit, @cur_user).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def role_edit
      set_item
      return "404" if @item.users.blank?
      render :role_edit
    end

    def role_update
      set_item
      role_ids = params[:item][:sys_role_ids].select(&:present?).map(&:to_i)

      @item.users.each do |user|
        user.set(sys_role_ids: role_ids)
      end
      render_update true
    end
end
