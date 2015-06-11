class Cms::Role
  include SS::Model::Role
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_users", :edit

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  validates :permission_level, presence: true

  public
    def permission_level_options
      [%w(1 1), %w(2 2), %w(3 3)]
    end

    #def allowed?(action, user, opts = {})
    #  return true if Cms::User.allowed?(action, user)
    #  super
    #end

  class << self
    public
      #def allow(action, user, opts = {})
      #  return where({}) if Cms::User.allowed?(action, user)
      #  super
      #end
  end
end
