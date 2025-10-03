class Gws::Schedule::TreeGroupComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group

  self.cache_key = ->do
    group_aggregates = all_groups.aggregates(:updated)
    user_aggregates = all_users.aggregates(:updated)
    [ cur_site.id, group_aggregates["count"], group_aggregates["max"].to_i, user_aggregates["count"], user_aggregates["max"].to_i ]
  end

  def root_nodes
    @root_nodes ||= Gws::GroupTreeComponent::TreeBuilder.new(items: all_groups, item_url_p: method(:item_url)).call
  end

  private

  def all_groups
    @all_groups ||= begin
      criteria = Gws::Group.site(cur_site)
      criteria = criteria.active
      criteria = criteria.allow(:read, cur_user, site: cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def all_users
    @all_users ||= Gws::User.all.site(cur_site).active
  end

  def group_id_user_map
    @group_id_user_map ||= begin
      map = {}
      all_users.to_a.each do |user|
        user.group_ids.each do |group_id|
          map[group_id] ||= []
          map[group_id] << user
        end
      end
      map
    end
  end

  def item_url(group)
    if group_id_user_map[group.id]
      gws_schedule_group_plans_path(site: cur_site, group: group)
    end
  end
end
