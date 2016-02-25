class Gws::Role
  include SS::Model::Role
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_roles", :edit

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  validates :permission_level, presence: true

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end
end
