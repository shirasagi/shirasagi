module Gws
  extend Sys::ModulePermission

  module_function

  mattr_accessor(:module_usable_handlers) { {} }

  def module_usable(name, proc = nil, &block)
    proc = block if block_given?
    module_usable_handlers[name.to_sym] = proc
  end

  def module_usable?(name, site, user)
    handler = module_usable_handlers[name.to_sym]
    return true if handler.nil?

    handler.call(site, user)
  end
end
