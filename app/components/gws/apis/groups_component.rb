class Gws::Apis::GroupsComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = ->{ [ cur_site.id, max_updated.to_i ] }

  def initialize(cur_site:, multi:)
    super()
    @cur_site = cur_site
    @multi = multi
  end

  attr_reader :cur_site, :multi

  def site_root
    @site_root ||= @cur_site.root
  end

  def groups
    @groups = Gws::Group.site(@cur_site).active.tree_sort
  end

  def max_updated
    @max_updated ||= Gws::Group.site(@cur_site).active.max(:updated)
  end
end
