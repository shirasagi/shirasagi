# coding: utf-8
module Cms::Addon
  module OwnerPermission
    extend ActiveSupport::Concern
    extend SS::Addon
    
    set_order 600
    
    included do
      class_variable_set(:@@_permission_name, nil)
      
      field :permission_level, type: Integer, default: 1
      embeds_ids :groups, class_name: "SS::Group"
      permit_params :permission_level, group_ids: []
      
      def owned?(user)
        self.group_ids.each do |id|
          if user.group_ids.include?(id)
            return true
          end
        end
        return false
      end
      
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
        
        permit = "#{action}_other_#{permission_name}"
        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        if level
          #dump "cms_allow " +  permit
          return where(permission_level: {"$lte" => level }) 
        end
        
        permit = "#{action}_private_#{permission_name}"
        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        if level
          #dump "cms_allow " +  permit
          return self.in(group_ids: user.group_ids).where(permission_level: {"$lte" => level }) 
        end
        
        #dump "cms_allow " +  permit
        return where({_id: -1})
      end
      
    end
    
    def permission_level_options
      [%w[1 1], %w[2 2], %w[3 3]]
    end
    
    def allowed?(action, user, opts = {})
      site = opts[:site] ? opts[:site] : @cur_site
      node = opts[:node] ? opts[:node] : @cur_node
      
      if self.new_record?
        if node
          access = node.owned?(user) ? :private : :other
          permit_level = node.permission_level
        else
          access = :other
          permit_level = 1
        end
      else
        access = owned?(user) ? :private : :other
        permit_level = self.permission_level
      end
      
      permit = []
      permit << "#{action}_#{access}_#{self.class.permission_name}"
      permit << "#{action}_other_#{self.class.permission_name}"  if access == :private
      
      level = user.cms_roles.site(site).in(permissions: permit).pluck(:permission_level).max
      #dump "cms_allowed? " + permit.to_s + " #{level.to_s} >= #{permit_level}"
      (level && level >= permit_level) ? true : false
    end
    
  end
end
