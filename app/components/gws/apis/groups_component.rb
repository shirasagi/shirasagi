class Gws::Apis::GroupsComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :multi

  self.cache_key = ->do
    group_aggregates = all_groups.aggregates(:updated)
    [ cur_site.id, group_aggregates["count"], group_aggregates["max"].to_i ]
  end

  def root_nodes
    @root_nodes ||= Gws::GroupTreeComponent::TreeBuilder.new(items: all_groups, item_url_p: method(:item_url)).call
  end

  private

  def all_groups
    @all_groups ||= begin
      criteria = Gws::Group.site(cur_site)
      criteria = criteria.active
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def item_url(_group)
    nil
  end
end
