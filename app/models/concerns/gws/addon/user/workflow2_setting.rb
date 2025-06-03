module Gws::Addon::User::Workflow2Setting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_gws_superior_group_ids, :in_gws_superior_user_ids

    field :gws_superior_group_ids, type: Hash, default: {}
    field :gws_superior_user_ids, type: Hash, default: {}
    permit_params in_gws_superior_group_ids: []
    permit_params in_gws_superior_user_ids: []

    before_validation :set_gws_superior_group_ids, if: ->{ @cur_site && in_gws_superior_group_ids }
    before_validation :set_gws_superior_user_ids, if: ->{ @cur_site && in_gws_superior_user_ids }
  end

  def gws_superior_groups(site = nil)
    return @gws_superior_groups if @gws_superior_groups

    site ||= @cur_site
    return nil unless site

    @gws_superior_groups = find_gws_superior_groups(site)
    return @gws_superior_groups if @gws_superior_groups.present?

    @gws_superior_groups = gws_default_group(site).gws_superior_groups
  end

  def find_gws_superior_groups(site = nil)
    site ||= @cur_site
    return nil unless site

    return [] if gws_superior_group_ids.blank?

    group_ids = gws_superior_group_ids[site.id.to_s]
    return [] if group_ids.blank?

    ::Gws::Group.in_group(site).in(id: group_ids).active.to_a
  end

  def gws_superior_users(site = nil)
    return @gws_superior_users if @gws_superior_users

    site ||= @cur_site
    return nil unless site

    @gws_superior_users = find_gws_superior_users(site)
    return @gws_superior_users if @gws_superior_users.present?

    @gws_superior_users = gws_default_group(site).gws_superior_users
  end

  def find_gws_superior_users(site = nil)
    site ||= @cur_site
    return nil unless site

    return [] if gws_superior_user_ids.blank?

    user_ids = gws_superior_user_ids[site.id.to_s]
    return [] if user_ids.blank?

    ::Gws::User.in(id: user_ids).active.to_a
  end

  private

  def set_gws_superior_group_ids
    ids = gws_superior_group_ids.presence || {}
    ids[@cur_site.id.to_s] = in_gws_superior_group_ids.to_a.select(&:present?).map(&:to_i)
    self.gws_superior_group_ids = ids
  end

  def set_gws_superior_user_ids
    ids = gws_superior_user_ids.presence || {}
    ids[@cur_site.id.to_s] = in_gws_superior_user_ids.to_a.select(&:present?).map(&:to_i)
    self.gws_superior_user_ids = ids
  end
end
