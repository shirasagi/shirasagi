class Gws::Portal::GroupTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group, :state

  self.cache_key = -> do
    results = items.aggregates(:updated)
    [ cur_site.id, cur_user.id, results["count"], results["max"].to_i ]
  end

  def root_nodes
    @root_nodes ||= Gws::GroupTreeComponent::TreeBuilder.new(items: items, item_url_p: method(:item_url)).call
  end

  private

  def items
    @items ||= begin
      criteria = Gws::Group.site(cur_site)
      criteria = criteria.state(state)
      # criteria = criteria.allow(:read, cur_user, site: cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def all_portal_settings
    @all_portal_settings ||= begin
      criteria = Gws::Portal::GroupSetting.all
      criteria = criteria.site(cur_site)
      criteria.to_a
    end
  end

  def portal_group_id_to_portal_setting_map
    @portal_group_id_to_portal_setting_map ||= all_portal_settings.index_by(&:portal_group_id)
  end

  def item_url(group)
    portal = portal_group_id_to_portal_setting_map[group.id]
    portal ||= Gws::Portal::GroupSetting.build_new_setting(group, site: cur_site)
    if portal.portal_readable?(cur_user, site: cur_site)
      gws_portal_group_path(site: cur_site, group: group)
    end
  end
end
