module Sys::ModulePermission
  def self.extended(obj)
    obj.class_variable_set(:@@_permission_name, nil)
    obj.class_variable_set(:@@_permission_action, nil)
  end

  def permission_action
    class_variable_get(:@@_permission_action)
  end

  def permission_name
    class_variable_get(:@@_permission_name) || self.name.underscore.tr("/", "_")
  end

  def allowed?(action, user, opts = {})
    action = self.permission_action || action
    user.sys_role_permit_any?("#{action}_#{self.permission_name}")
  end

  private

  def set_permission_name(name, fix_action = nil)
    class_variable_set(:@@_permission_name, name)
    class_variable_set(:@@_permission_action, fix_action)
  end
end
