class Cms::User
  include SS::Model::User
  include Cms::Addon::Role
  include Cms::Reference::Role
  include Cms::SitePermission
  include Cms::Addon::Import::User
  include SS::Addon::UserGroupHistory

  set_permission_name "cms_users", :edit

  cattr_reader(:group_class) { Cms::Group }

  attr_accessor :cur_site

  validate :validate_groups

  scope :site, ->(site, opts = {}) do
    if opts[:state].present?
      self.in(group_ids: Cms::Group.unscoped.site(site).state(opts[:state]).pluck(:id))
    else
      self.in(group_ids: Cms::Group.site(site).pluck(:id))
    end
  end

  private
    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end
end
