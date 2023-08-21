module SS::Addon
  def self.extended(mod)
    mod.extend SS::Translation
  end

  def addon_name
    SS::Addon::Name.new(self, type: @addon_type)
  end

  def set_addon_type(addon_type)
    @addon_type = addon_type
  end
end
