# coding: utf-8
module Cms::Addon
  module Permission
    extend ActiveSupport::Concern
    
    included do
      class_variable_set(:@@_permission_name, nil)
    end
    
    module ClassMethods
      def set_permission_name(name)
         class_variable_set(:@@_permission_name, name)
      end
      
      def permission_name
        if class_variable_get(:@@_permission_name)
          class_variable_get(:@@_permission_name)
        else
          self.to_s.tableize.gsub(/\//, "_")
        end
      end
      
      def allowed?(action, user, opts = {})
        self.new.allowed?(action, user, opts)
      end
      
      def allow(action, user, opts = {})
        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
        
        permit = "#{action}_#{permission_name}"
        role = user.cms_roles.where(site_id:  site_id).in(permissions: permit).first
        #dump "cms_allow " + permit
        if role
          return where({})
        end
        
        return where({_id: -1})
      end
      
    end
    
    def allowed?(action, user, opts = {})
      site = opts[:site] ? opts[:site] : @cur_site
      node = opts[:node] ? opts[:node] : @cur_node
      
      permit = "#{action}_#{self.class.permission_name}"
      #dump "cms_allowed? " + permit
      
      role = user.cms_roles.site(site).in(permissions: permit).first
      role ? true : false
    end
    
  end
end
