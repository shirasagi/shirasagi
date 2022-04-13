class Gws::Apis::GroupDropdownTreeComponent < ApplicationComponent
  include SS::CacheableComponent

  self.expires_in = Gws::FRAGMENT_CACHE_EXPIRES_IN
  self.cache_key = ->{ [ @cur_site.id, max_updated.to_i ] }

  def initialize(cur_site:)
    super()
    @cur_site = cur_site
  end

  attr_reader :cur_site

  def groups
    @groups ||= @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)
  end

  def max_updated
    @max_updated ||= @cur_site.descendants.active.max(:updated)
  end
end
