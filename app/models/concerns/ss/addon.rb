module SS::Addon
  def self.extended(mod)
    mod.extend SS::Translation
  end

  def addon_disabled?
    section, *paths, name = self.name.underscore.split('/')
    return false unless SS.config.respond_to?(section)

    config = SS.config.send(section).to_h.stringify_keys
    paths.each do |path|
      return false unless config.key?(path)
      config = config[path]
      return false unless config.is_a?(Hash)
    end

    !config.fetch(name, true)
  end

  def addon_name
    return nil if addon_disabled?
    SS::Addon::Name.new(self)
  end
end
