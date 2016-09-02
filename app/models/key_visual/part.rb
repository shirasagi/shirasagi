module KeyVisual::Part
  class Slide
    include Cms::Model::Part
    include KeyVisual::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Part

    default_scope ->{ where(route: "key_visual/slide") }
  end
end
