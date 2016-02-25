class SS::Migration20160225000000
  def change
    Sys::Role.where(permissions: 'edit_sys_users').each do |item|
      permissions = item.permissions
      %w(
        edit_sys_groups
        edit_sys_roles
      ).each do |name|
        permissions << name unless item.permissions.include?(name)
      end
      item.permissions = permissions
      item.save! if item.changed?
    end

    Cms::Role.where(permissions: 'edit_cms_users').each do |item|
      permissions = item.permissions
      %w(
        edit_cms_groups
        edit_cms_roles
        edit_cms_members
        edit_cms_editor_templates
        use_cms_tools
        edit_chorg_revisions
        read_other_workflow_routes
        read_private_workflow_routes
        edit_other_workflow_routes
        edit_private_workflow_routes
        delete_other_workflow_routes
        delete_private_workflow_routes
      ).each do |name|
        permissions << name unless item.permissions.include?(name)
      end
      item.permissions = permissions
      item.save! if item.changed?
    end

    Gws::Role.where(permissions: 'edit_gws_users').each do |item|
      permissions = item.permissions
      %w(
        edit_gws_groups
        edit_gws_roles
        read_other_gws_workflow_routes
        read_private_gws_workflow_routes
        edit_other_gws_workflow_routes
        edit_private_gws_workflow_routes
        delete_other_gws_workflow_routes
        delete_private_gws_workflow_routes
      ).each do |name|
        permissions << name unless item.permissions.include?(name)
      end
      item.permissions = permissions
      item.save! if item.changed?
    end
  end
end
