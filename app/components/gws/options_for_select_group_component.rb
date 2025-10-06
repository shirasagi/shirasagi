class Gws::OptionsForSelectGroupComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :selected

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
      criteria = Gws::Group.unscoped.site(cur_site)
      criteria = criteria.active
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def item_url(_group)
    nil
  end
end