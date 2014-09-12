# coding: utf-8
class Cms::Group
  include SS::Group::Model
  include Cms::Permission

  set_permission_name "cms_users", :edit

  scope :site, ->(site) { self.in(name: site.groups.pluck(:name).map{ |name| /^#{name}(\/|$)/ }) }
end
