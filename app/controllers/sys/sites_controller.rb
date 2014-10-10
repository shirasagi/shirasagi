class Sys::SitesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Site

  menu_view "sys/crud/menu"

  private
    def set_crumbs
      @crumbs << [:"sys.site", sys_sites_path]
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)
      @items = @model.allow(:edit, @cur_user).
        order_by(_id: -1)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      result = @item.save
      if result
        permissions = %w(
          edit_cms_sites
          edit_cms_users
          read_other_cms_nodes
          read_other_cms_pages
          read_other_cms_parts
          read_other_cms_layouts
          edit_other_cms_nodes
          edit_other_cms_pages
          edit_other_cms_parts
          edit_other_cms_layouts
          delete_other_cms_nodes
          delete_other_cms_pages
          delete_other_cms_parts
          delete_other_cms_layouts
          read_other_article_pages
          edit_other_article_pages
          delete_other_article_pages
        )

        cond = {
          site_id: @item.id,
          name: "admin",
          permissions: permissions,
          permission_level: 3
        }

        role = Cms::Role.find_or_create_by cond
        @cur_user.add_to_set cms_role_ids: role.id
        @cur_user.update
      end

      render_create result
    end
end
