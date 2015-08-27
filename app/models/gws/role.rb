class Gws::Role
  include SS::Model::Role
  include Gws::Permission

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  set_permission_name "gws_users", :edit

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end

  #TODO:
  scope :site, ->(p) { where({}) }
end
