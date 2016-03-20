class Cms::Group
  include SS::Model::Group
  include Cms::SitePermission
  include Contact::Addon::Group
  include Cms::Addon::Import::Group

  set_permission_name "cms_groups", :edit

  attr_accessor :cur_site, :cms_role_ids
  permit_params :cms_role_ids

  scope :site, ->(site) { self.in(name: site.groups.pluck(:name).map{ |name| /^#{Regexp.escape(name)}(\/|$)/ }) }

  validate :validate_sites, if: ->{ cur_site.present? }

  def users
    Cms::User.in(group_ids: id)
  end

  private
    def validate_sites
      return if cur_site.group_ids.index(id)

      cond = cur_site.groups.map { |group| name =~ /^#{Regexp.escape(group.name)}\// }.compact
      self.errors.add :name, :not_a_child_group if cond.blank?
    end
end
