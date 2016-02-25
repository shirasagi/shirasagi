class Sys::Role
  include SS::Model::Role
  include Sys::Permission

  set_permission_name "sys_roles", :edit

  field :permissions, type: SS::Extensions::Words, overwrite: true

  validates :permissions, presence: true
end
