# coding: utf-8
class Cms::Site
  include SS::Site::Model
  include Cms::Addon::Permission
  
  set_permission_name "cms_sites"
end
