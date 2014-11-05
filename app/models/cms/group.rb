class Cms::Group
  include SS::Group::Model
  include Cms::Permission
  include Contact::Addon::Group

  set_permission_name "cms_users", :edit

  attr_accessor :cur_site

  scope :site, ->(site) { self.in(name: site.groups.pluck(:name).map{ |name| /^#{name}(\/|$)/ }) }

  validate :validate_sites

  private
    def validate_sites
      if cur_site.present?
        return if cur_site.group_ids.index(id)

        cond = cur_site.groups.map { |group| name =~ /^#{group.name}\// }.compact
        self.errors.add :name, :not_a_child_group if cond.blank?
      end
    end
end
