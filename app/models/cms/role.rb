class Cms::Role
  include SS::Model::Role
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_users", :edit

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  validates :permission_level, presence: true

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end
end
