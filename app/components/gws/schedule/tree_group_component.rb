class Gws::Schedule::TreeGroupComponent < ApplicationComponent
  include SS::CacheableComponent

  self.cache_key = ->{ [ cur_site.id, group_max_updated.to_i, user_max_updated.to_i ] }

  def initialize(cur_site:)
    super()
    @cur_site = cur_site
  end

  attr_reader :cur_site

  def groups
    @groups ||= cur_site.descendants.active.tree_sort(root_name: cur_site.name)
  end

  def group_max_updated
    @group_max_updated ||= cur_site.descendants.max(:updated)
  end

  def user_max_updated
    @user_max_updated ||= Gws::User.all.site(cur_site).max(:updated)
  end
end
