module Map::Part
  class GeolocationPage
    include Cms::Model::Part
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    self.use_sort = false
    self.use_new_days = false

    default_scope ->{ where(route: "map/page") }
  end
end
