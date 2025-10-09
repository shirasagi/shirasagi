class Gws::Presence::TreeGroupComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = -> do
    group_aggregates = all_groups.aggregates(:updated)
    [ cur_site.id, group_aggregates["count"], group_aggregates["max"].to_i ]
  end

  def initialize(cur_site:)
    super()
    @cur_site = cur_site
  end

  attr_reader :cur_site

  def root_groups
    @root_groups ||= Gws::GroupTreeComponent::TreeBuilder.new(items: all_groups, item_url_p: method(:item_url)).call
  end

  def max_updated
    @max_updated ||= site_root.descendants_and_self.active.max(:updated)
  end

  private

  def all_groups
    @all_groups ||= begin
      criteria = Gws::Group.unscoped.site(cur_site)
      criteria = criteria.active
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def item_url(group)
    gws_presence_group_users_path(site: cur_site, group: group)
  end
end
