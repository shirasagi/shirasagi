class Gws::Apis::GroupDropdownTreeComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = ->{ [ cur_site.id, max_updated.to_i ] }

  def initialize(cur_site:)
    super()
    @cur_site = cur_site
  end

  attr_reader :cur_site

  def site_root
    @site_root ||= @cur_site.root
  end

  def groups
    @groups ||= site_root.descendants.active.tree_sort(root_name: @cur_site.name)
  end

  def max_updated
    @max_updated ||= site_root.descendants.active.max(:updated)
  end
end
