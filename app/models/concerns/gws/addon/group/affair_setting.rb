module Gws::Addon::Group::AffairSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :superior_groups, class_name: "Gws::Group"
    embeds_ids :superior_users, class_name: "Gws::User"

    permit_params superior_group_ids: []
    permit_params superior_user_ids: []
  end

  def gws_superior_users
    superior_users
  end

  def gws_superior_groups
    superior_groups.presence || default_superior_groups
  end

  def default_superior_groups
    @_parents = parents.to_a.select(&:active?)
    @_parents.present? ? [@_parents.last] : [self]
  end
end
