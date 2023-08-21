module Gws::Workload::Graph
  extend Gws::ModulePermission

  set_permission_name :gws_workload_graphs

  module_function

  def allowed_other?(user, opts = {})
    allowed?(:read_other, user, opts)
  end

  def allowed_self?(user, opts = {})
    allowed_other?(user, opts) || allowed?(:read_private, user, opts)
  end
end
