class Gws::Portal::GroupTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group, :state

  self.cache_key = -> do
    results = items.aggregates(:updated)
    [ site.id, results["count"], results["max"].to_i ]
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

  def item_url(group)
    gws_portal_group_path(site: cur_site, group: group)
  end
end
