class Gws::User
  include SS::Model::User
  include Gws::Reference::UserTitles
  include Gws::Reference::UserOccupations
  include Gws::Referenceable
  include Gws::SitePermission
  include Gws::Addon::User::PublicDuty
  include Gws::Addon::User::AffairSetting
  include Gws::Addon::User::DutyHour
  include Gws::Addon::User::CustomForm
  include Gws::Addon::User::Presence
  include Gws::Addon::Memo::MessageSort
  include Gws::Addon::Role
  include Gws::Addon::ReadableSetting
  include SS::Addon::UserGroupHistory
  include Gws::Addon::History
  include Sys::Reference::Role
  include Webmail::Reference::Role

  set_permission_name "gws_users", :edit

  cattr_reader(:group_class) { Gws::Group }

  attr_accessor :in_title_id, :in_occupation_id, :in_gws_main_group_id, :in_gws_default_group_id

  # 管理者がユーザ管理画面で設定した主グループ。ユーザーの主務を表しており、あまり変更はない。
  field :gws_main_group_ids, type: Hash, default: {}
  # ユーザーがグループ切り替え機能を用いて設定したアクティブグループ。ユーザーの兼務を表しており、しょっちゅう変わる。
  field :gws_default_group_ids, type: Hash, default: {}

  embeds_ids :groups, class_name: "Gws::Group"

  permit_params :in_title_id, :in_occupation_id, :in_gws_main_group_id, :in_gws_default_group_id

  before_validation :set_title_ids, if: ->{ in_title_id }
  before_validation :set_occupation_ids, if: ->{ in_occupation_id }
  before_validation :set_gws_main_group_id, if: ->{ @cur_site && in_gws_main_group_id }
  before_validation if: ->{ @cur_site && in_gws_default_group_id } do
    set_gws_default_group_id(in_gws_default_group_id)
  end
  validate :validate_groups
  validate :validate_gws_main_group, if: ->{ @cur_site }
  validate :validate_gws_default_group, if: ->{ @cur_site }

  # reset default order
  self.default_scoping = nil if default_scopable?

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  scope :readable_users, ->(user, opts = {}) {
    return all if self.allowed?(:read, user, opts)
    or_conds = readable_conditions(user, opts)
    or_conds.unshift({ id: user.id })
    where("$and" => [{ "$or" => or_conds }])
  }

  def readable_user?(user, opts = {})
    return true if id == user.id

    opts[:site] ||= self.site

    return true if self.class.allowed?(:read, user, opts)
    return true if !readable_setting_present?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    return true if readable_custom_groups.any? { |m| m.member_ids.include?(user.id) }
    false
  end

  def title_id_options
    Gws::UserTitle.site(cur_site).active.map { |m| [m.name_with_code, m.id] }
  end

  def occupation_id_options
    Gws::UserOccupation.site(cur_site).active.map { |m| [m.name_with_code, m.id] }
  end

  def set_gws_default_group_id(group_id)
    ids = gws_default_group_ids.presence || {}
    if group_id.numeric?
      ids[@cur_site.id.to_s] = group_id.to_i
    else
      ids.delete(@cur_site.id.to_s)
    end

    self.gws_default_group_ids = ids
  end

  def gws_default_group(site = nil)
    return @gws_default_group if @gws_default_group

    site ||= @cur_site
    return nil unless site

    @gws_default_group = find_gws_default_group(site)
    @gws_default_group ||= find_gws_main_group(site)
  end

  def find_gws_default_group(site = nil)
    return if gws_default_group_ids.blank?

    site ||= @cur_site
    group_id = gws_default_group_ids[site.id.to_s]
    return if group_id.blank?

    group_id = group_id.to_i if group_id.numeric? # for backwards compatibility
    ids = Array(group_id).compact & self.group_ids
    return if ids.blank?

    groups.in_group(site).in(id: ids).active.first
  end

  def find_gws_main_group(site = nil)
    site ||= @cur_site

    group_id = gws_main_group_ids[site.id.to_s]
    ids = Array(group_id).compact & self.group_ids
    if ids.present?
      main_group = groups.in_group(site).in(id: ids).active.first
    end
    main_group ||= groups.in_group(site).active.first
    main_group
  end
  alias gws_main_group find_gws_main_group

  private

  def set_title_ids
    title_ids = titles.reject { |m| m.group_id == cur_site.id }.map(&:id)
    title_ids << in_title_id.to_i if in_title_id.present?
    self.title_ids = title_ids
  end

  def set_occupation_ids
    occupation_ids = occupations.reject { |m| m.group_id == cur_site.id }.map(&:id)
    occupation_ids << in_occupation_id.to_i if in_occupation_id.present?
    self.occupation_ids = occupation_ids
  end

  def set_gws_main_group_id
    group_ids = gws_main_group_ids
    if in_gws_main_group_id.numeric?
      group_ids[@cur_site.id.to_s] = in_gws_main_group_id.to_i
    else
      group_ids.delete(@cur_site.id.to_s)
    end

    self.gws_main_group_ids = group_ids
  end

  def validate_groups
    self.errors.add :group_ids, :blank if groups.blank?
  end

  def validate_gws_main_group
    return true if @cur_site.blank?

    group_id = gws_main_group_ids[@cur_site.id.to_s]
    return true if group_id.blank?
    return true if group_ids.include?(group_id) && @cur_site.descendants_and_self.active.where(id: group_id).present?

    errors.add :gws_main_group_ids, :invalid
  end

  def validate_gws_default_group
    return true if @cur_site.blank?

    group_id = gws_default_group_ids[@cur_site.id.to_s]
    return true if group_id.blank?
    return true if group_ids.include?(group_id) && @cur_site.descendants_and_self.active.where(id: group_id).present?

    errors.add :gws_default_group_ids, :invalid
  end
end
