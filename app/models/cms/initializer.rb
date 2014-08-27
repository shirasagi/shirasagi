# coding: utf-8
module Cms
  class Initializer
    Cms::User.addon "cms/role"
    Cms::Page.addon "cms/meta"
    Cms::Page.addon "cms/body"
    Cms::Page.addon "cms/file"
    Cms::Page.addon "cms/release"

    Cms::Node.plugin "cms/node"
    Cms::Node.plugin "cms/page"
    Cms::Part.plugin "cms/free"
    Cms::Part.plugin "cms/node"
    Cms::Part.plugin "cms/page"
    Cms::Part.plugin "cms/tabs"
    Cms::Part.plugin "cms/crumb"

    Cms::Role.permission :edit_cms_sites
    Cms::Role.permission :edit_cms_users
    Cms::Role.permission :read_other_cms_nodes
    Cms::Role.permission :read_other_cms_pages
    Cms::Role.permission :read_other_cms_parts
    Cms::Role.permission :read_other_cms_layouts
    Cms::Role.permission :read_private_cms_nodes
    Cms::Role.permission :read_private_cms_pages
    Cms::Role.permission :read_private_cms_parts
    Cms::Role.permission :read_private_cms_layouts
    Cms::Role.permission :edit_other_cms_nodes
    Cms::Role.permission :edit_other_cms_pages
    Cms::Role.permission :edit_other_cms_parts
    Cms::Role.permission :edit_other_cms_layouts
    Cms::Role.permission :edit_private_cms_nodes
    Cms::Role.permission :edit_private_cms_pages
    Cms::Role.permission :edit_private_cms_parts
    Cms::Role.permission :edit_private_cms_layouts
    Cms::Role.permission :delete_other_cms_nodes
    Cms::Role.permission :delete_other_cms_pages
    Cms::Role.permission :delete_other_cms_parts
    Cms::Role.permission :delete_other_cms_layouts
    Cms::Role.permission :delete_private_cms_nodes
    Cms::Role.permission :delete_private_cms_pages
    Cms::Role.permission :delete_private_cms_parts
    Cms::Role.permission :delete_private_cms_layouts
  end
end
