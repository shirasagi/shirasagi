class Gws::User
  include SS::Model::User
  include Gws::SitePermission
  include Gws::Addon::Role
  include SS::Addon::UserGroupHistory

  set_permission_name "gws_users", :edit

  cattr_reader(:group_class) { Gws::Group }

  attr_accessor :in_title_id, :in_gws_main_group_id

  field :gws_main_group_ids, type: Hash, default: {}
  field :gws_default_group_ids, type: Hash, default: {}

  embeds_ids :groups, class_name: "Gws::Group"

  permit_params :in_title_id, :in_gws_main_group_id

  before_validation :set_title_ids, if: ->{ in_title_id }
  before_validation :set_gws_main_group_id, if: ->{ @cur_site && in_gws_main_group_id }
  validate :validate_groups
  validate :validate_gws_main_group, if: ->{ @cur_site }

  # reset default order
  self.default_scoping = nil if default_scopable?

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  def title_id_options
    Gws::UserTitle.site(cur_site).active.map { |m| [m.name, m.id] }
  end

  def set_gws_default_group_id(group_id)
    ids = gws_default_group_ids.presence || {}
    ids[@cur_site.id.to_s] = group_id
    self.gws_default_group_ids = ids
    save
  end

  def gws_default_group
    return @gws_default_group if @gws_default_group
    return nil unless @cur_site
    if gws_default_group_ids.present? && group_id = gws_default_group_ids[@cur_site.id.to_s]
      @gws_default_group = groups.in_group(@cur_site).where(id: group_id).first
    end
    @gws_default_group ||= groups.in_group(@cur_site).first
  end

  def gws_main_group(site = nil)
    site ||= @cur_site
    if group_id = gws_main_group_ids[site.id.to_s]
      main_group = groups.in_group(site).where(id: group_id).first
    end
    main_group ||= groups.in_group(site).first
    main_group
  end

  private
    def set_title_ids
      title_ids = titles.reject { |m| m.group_id == cur_site.id }.map(&:id)
      title_ids << in_title_id.to_i if in_title_id.present?
      self.title_ids = title_ids
    end

    def set_gws_main_group_id
      group_ids = gws_main_group_ids
      group_ids[@cur_site.id.to_s] = in_gws_main_group_id.present? ? in_gws_main_group_id.to_i : nil
      self.gws_main_group_ids = group_ids.select { |k, v| v.present? }
    end

    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end

    def validate_gws_main_group
      group_id = gws_main_group_ids[@cur_site.id.to_s]
      return true if group_id.blank?
      return true if group_ids.include?(group_id)
      errors.add :gws_main_group_ids, :invalid
    end
end
