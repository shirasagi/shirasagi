class Cms::Role
  include SS::Role::Model
  include SS::Reference::Site
  include Cms::Permission

  set_permission_name "cms_users", :edit

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  validates :permission_level, presence: true

  public
    def permission_level_options
      [%w(1 1), %w(2 2), %w(3 3)]
    end

    def allowed?(action, user, opts = {})
      return true if Sys::User.allowed?(action, user)
      super
    end

  class << self
    public
      def allow(action, user, opts = {})
        return where({}) if Sys::User.allowed?(action, user)
        super
      end
  end
end
