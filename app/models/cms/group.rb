class Cms::Group
  include SS::Model::Group
  include Cms::SitePermission
  include Contact::Addon::Group

  set_permission_name "cms_groups", :edit

  attr_accessor :cur_site, :cms_role_ids

  permit_params :cms_role_ids

  default_scope -> { active }
  scope :site, ->(site) { self.in(name: site.groups.pluck(:name).map{ |name| /^#{::Regexp.escape(name)}(\/|$)/ }) }

  validate :validate_sites, if: ->{ cur_site.present? }

  class << self
    SEARCH_HANDLERS = %i[search_name search_keyword].freeze

    def search(params)
      SEARCH_HANDLERS.reduce(all) { |criteria, handler| criteria.send(handler, params) }
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(
        params[:keyword], :name, "contact_groups.name", "contact_groups.contact_group_name", "contact_groups.contact_charge",
        "contact_groups.contact_tel", "contact_groups.contact_fax", "contact_groups.contact_email",
        "contact_groups.contact_link_url", "contact_groups.contact_link_name")
    end
  end

  def users
    Cms::User.in(group_ids: id)
  end

  private

  def validate_sites
    return if cur_site.group_ids.index(id)

    cond = cur_site.groups.map { |group| name =~ /^#{::Regexp.escape(group.name)}\// }.compact
    self.errors.add :name, :not_a_child_group if cond.blank?
  end
end
