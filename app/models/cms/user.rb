# coding: utf-8
class Cms::User
  include SS::User::Model
  include Cms::Addon::Permission

  set_permission_name "cms_users"

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }

  validate :validate_groups

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
        return self if Sys::User.allowed?(action, user)
        super
      end
  end
end
