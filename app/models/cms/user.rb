class Cms::User
  include SS::User::Model
  include Cms::Addon::Role
  include Cms::Permission

  set_permission_name "cms_users", :edit

  validate :validate_groups

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }

  public
    def allowed?(action, user, opts = {})
      return true if Sys::User.allowed?(action, user)
      super
    end

  private
    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end

  class << self
    public
      def allow(action, user, opts = {})
        return where({}) if Sys::User.allowed?(action, user)
        super
      end
  end
end
