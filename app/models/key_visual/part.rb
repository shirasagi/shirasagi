module KeyVisual::Part
  class Slide
    include Cms::Model::Part
    include KeyVisual::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "key_visual/slide") }
  end

  class SwiperSlide
    include Cms::Model::Part
    include KeyVisual::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "key_visual/swiper_slide") }
  end
end
