class Gws::User
  include SS::Model::User
  include Gws::Addon::Role
  include Gws::Reference::Role
  include Gws::SitePermission

  set_permission_name "gws_users", :edit

  cattr_reader(:group_class) { Gws::Group }

  attr_accessor :cur_site

  embeds_ids :groups, class_name: "Gws::Group"

  validate :validate_groups

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  private
    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end
end
