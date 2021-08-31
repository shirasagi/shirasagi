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
    include Cms::Addon::PageList
    include KeyVisual::Addon::SwiperSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    self.use_no_items_display = false
    self.use_substitute_html = false
    self.use_no_archive_html = false
    self.use_loop_html = false
    self.use_new_days = false
    self.use_liquid = false
    self.use_sort = false
    self.use_conditions = false

    default_scope ->{ where(route: "key_visual/swiper_slide") }
  end
end
