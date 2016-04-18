class Gws::User
  include SS::Model::User
  include Gws::SitePermission
  include Gws::Addon::Role
  include SS::Addon::UserGroupHistory

  set_permission_name "gws_users", :edit

  cattr_reader(:group_class) { Gws::Group }

  attr_accessor :in_title_id

  embeds_ids :groups, class_name: "Gws::Group"

  permit_params :in_title_id

  before_validation :set_title_ids, if: ->{ in_title_id }
  validate :validate_groups

  # reset default order
  self.default_scoping = nil if default_scopable?

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  def title_id_options
    Gws::UserTitle.site(cur_site).active.map { |m| [m.name, m.id] }
  end

  private
    def set_title_ids
      title_ids = titles.reject { |m| m.group_id == cur_site.id }.map(&:id)
      title_ids << in_title_id.to_i if in_title_id.present?
      self.title_ids = title_ids
    end

    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end
end
